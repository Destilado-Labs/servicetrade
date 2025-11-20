module ServiceTrade
  class Attachment < BaseResource
    extend ServiceTrade::ApiOperations::List

    OBJECT_NAME = 'attachment'.freeze

    # Core attachment attributes
    attr_reader :id, :uri, :name, :description, :file_type, :size,
                :created, :updated, :category, :purpose, :url, :content_url

    # Related objects
    attr_reader :job, :location, :uploaded_by

    def self.resource_url
      OBJECT_NAME
    end

    # Find a specific attachment by ID
    def self.find(id)
      response = ServiceTrade.client.request(:get, "#{resource_url}/#{id}")
      new(response['data'])
    end

    # List method with filtering support
    def self.list(filters = {}, page: 1, per_page: 100)
      super(filters, page: page, per_page: per_page)
    end

    # Get attachments for a specific job
    def self.for_job(job_id, page: 1, per_page: 100)
      params = {
        page: page,
        per_page: per_page
      }
      response = ServiceTrade.client.request(:get, "job/#{job_id}/attachment", params, {})
      ListResponse.new(response, self)
    end
  end
end
