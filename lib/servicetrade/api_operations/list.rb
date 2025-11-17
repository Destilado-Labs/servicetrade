# lib/servicetrade/api_operations/list.rb
module ServiceTrade
  module ApiOperations
    module List
      def list(filters = {}, page: 1, per_page: 100)
        params = filters.merge({
          page: page,
          per_page: per_page
        })

        response = ServiceTrade.client.request(:get, resource_url, params, {})
        ListResponse.new(response, self)
      end

      # Iterator method for automatically handling pagination
      def all(filters = {}, per_page: 100, &block)
        if block_given?
          page = 1
          loop do
            response = list(filters, page: page, per_page: per_page)
            response.data.each(&block)
            break unless response.has_more?
            page += 1
          end
        else
          Enumerator.new do |yielder|
            page = 1
            loop do
              response = list(filters, page: page, per_page: per_page)
              response.data.each { |item| yielder << item }
              break unless response.has_more?
              page += 1
            end
          end
        end
      end
    end
  end

  class ListResponse
    attr_reader :data, :total_count, :page, :per_page

    def initialize(response, resource_class)
      # Handle ServiceTrade API response format
      data_key = case resource_class.name.split('::').last.downcase
                 when 'job'
                   'jobs'
                 when 'appointment'
                   'appointments'
                 when 'location'
                   'locations'
                 when 'region'
                   'regions'
                 when 'company'
                   'companies'
                 when 'contact'
                   'contacts'
                 when 'servicerequest'
                   'servicerequests'
                 when 'serviceline'
                   'servicelines'
                 when 'webhook'
                   'webhooks'
                 when 'libitem'
                   'libItems'
                 when 'jobitem'
                   'jobItems'
                 else
                   'data'
                 end

      items = response.dig('data', data_key) || response['data'] || []
      @data = items.map { |item| resource_class.new(item) }
      @total_count = response.dig('data', 'total') || response['total'] || items.length
      @page = response.dig('data', 'page') || response['page'] || 1
      @per_page = response.dig('data', 'per_page') || response['per_page'] || items.length
    end

    def has_more?
      (@page * @per_page) < @total_count
    end
  end
end
