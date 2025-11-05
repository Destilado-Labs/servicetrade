module ServiceTrade
  class Appointment < BaseResource
    extend ServiceTrade::ApiOperations::Create
    extend ServiceTrade::ApiOperations::List
    extend ServiceTrade::ApiOperations::Update
    extend ServiceTrade::ApiOperations::Delete

    OBJECT_NAME = 'appointment'.freeze

    # Core appointment attributes
    attr_reader :id, :uri, :status, :scheduled_date, :scheduled_time,
                :duration, :description, :created, :updated

    # Related objects
    attr_reader :job, :vendor, :customer, :location, :assigned_to,
                :assigned_office, :notes

    def self.resource_url
      OBJECT_NAME
    end

    # Find a specific appointment by ID
    def self.find(id)
      response = ServiceTrade.client.request(:get, "#{resource_url}/#{id}")
      new(response['data'])
    end

    # Enhanced list method with filtering support
    def self.list(filters = {}, page: 1, per_page: 100)
      # Use the pagination from the List module
      super(filters, page: page, per_page: per_page)
    end

    # Create a new appointment
    def self.create(params = {})
      response = ServiceTrade.client.request(:post, resource_url, params)
      new(response['data'])
    end

    # Update an existing appointment
    def self.update(id, params = {})
      response = ServiceTrade.client.request(:put, "#{resource_url}/#{id}", params)
      new(response['data'])
    end

    # Update this appointment instance
    def update(params = {})
      self.class.update(id, params)
    end

    # Delete an appointment
    def self.delete(id)
      ServiceTrade.client.request(:delete, "#{resource_url}/#{id}")
      true
    end

    # Delete this appointment instance
    def delete
      self.class.delete(id)
    end

    # Convenience methods for common appointment filtering
    def self.by_job(job_id, page: 1, per_page: 100)
      list({job_id: job_id}, page: page, per_page: per_page)
    end

    def self.by_status(status, page: 1, per_page: 100)
      list({status: status}, page: page, per_page: per_page)
    end

    def self.by_vendor(vendor_id, page: 1, per_page: 100)
      list({vendor_id: vendor_id}, page: page, per_page: per_page)
    end

    def self.by_customer(customer_id, page: 1, per_page: 100)
      list({customer_id: customer_id}, page: page, per_page: per_page)
    end

    def self.by_location(location_id, page: 1, per_page: 100)
      list({location_id: location_id}, page: page, per_page: per_page)
    end

    def self.scheduled_between(start_date, end_date, page: 1, per_page: 100)
      list({scheduled_date_begin: start_date, scheduled_date_end: end_date}, page: page, per_page: per_page)
    end
  end
end
