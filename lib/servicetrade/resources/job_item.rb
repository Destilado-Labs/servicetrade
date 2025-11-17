module ServiceTrade
  class JobItem < BaseResource
    extend ServiceTrade::ApiOperations::Create
    extend ServiceTrade::ApiOperations::List
    extend ServiceTrade::ApiOperations::Update
    extend ServiceTrade::ApiOperations::Delete

    OBJECT_NAME = 'jobitem'.freeze

    # Core job item attributes
    attr_reader :id, :uri, :description, :cost, :used_on, :created, :updated

    # Related objects
    attr_reader :job, :lib_item, :vendor

    # Additional fields that may be present
    attr_reader :quantity, :unit_price, :total, :type, :notes

    def self.resource_url
      OBJECT_NAME
    end

    # Find a specific job item by ID
    def self.find(id)
      response = ServiceTrade.client.request(:get, "#{resource_url}/#{id}")
      new(response['data'])
    end

    # Enhanced list method with filtering and pagination
    def self.list(filters = {}, page: 1, per_page: 100)
      # Use the pagination from the List module
      super(filters, page: page, per_page: per_page)
    end

    # Create a new job item
    def self.create(params = {})
      response = ServiceTrade.client.request(:post, resource_url, params)
      new(response['data'])
    end

    # Update an existing job item
    def self.update(id, params = {})
      response = ServiceTrade.client.request(:put, "#{resource_url}/#{id}", params)
      new(response['data'])
    end

    # Update this job item instance
    def update(params = {})
      self.class.update(id, params)
    end

    # Delete a job item
    def self.delete(id)
      ServiceTrade.client.request(:delete, "#{resource_url}/#{id}")
      true
    end

    # Delete this job item instance
    def delete
      self.class.delete(id)
    end

    # Convenience methods for common job item filtering
    def self.by_job(job_id, page: 1, per_page: 100)
      list({job_id: job_id}, page: page, per_page: per_page)
    end

    def self.by_lib_item(lib_item_id, page: 1, per_page: 100)
      list({lib_item_id: lib_item_id}, page: page, per_page: per_page)
    end

    def self.used_on_date(date, page: 1, per_page: 100)
      list({used_on: date}, page: page, per_page: per_page)
    end

    def self.used_between(start_date, end_date, page: 1, per_page: 100)
      list({used_on_begin: start_date, used_on_end: end_date}, page: page, per_page: per_page)
    end

    # Calculate total if quantity and unit_price are available
    def calculate_total
      return nil unless quantity && unit_price
      quantity * unit_price
    end

    # Get the total cost (use provided total or calculate it)
    def total_cost
      total || cost || calculate_total
    end
  end
end
