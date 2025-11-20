module ServiceTrade
  class Job < BaseResource
    extend ServiceTrade::ApiOperations::Create
    extend ServiceTrade::ApiOperations::List
    extend ServiceTrade::ApiOperations::Update
    extend ServiceTrade::ApiOperations::Delete

    OBJECT_NAME = 'job'.freeze

    # Core job attributes
    attr_reader :id, :uri, :name, :custom_name, :type, :job_type_weight,
                :status, :display_status, :substatus, :display_substatus,
                :number, :ref_number, :customer_po, :visibility, :section_visibilities,
                :description, :scheduled_date, :estimated_price, :latest_clock_in,
                :ivr_open, :ivr_activity, :service_line, :due_by, :due_after,
                :completed_on, :percent_complete, :is_project, :budgeted,
                :created, :updated

    # Related objects
    attr_reader :vendor, :customer, :location, :owner, :sales, :primary_contact,
                :current_appointment, :assigned_office, :offices, :tags,
                :external_ids, :terms, :contract, :project, :notes,
                :service_requests, :scheduling_comments

    # Service link visibility
    attr_reader :service_link_attachment_visibility, :service_link_comment_visibility,
                :service_link_attachment_category_visibility

    # Deprecated fields (kept for backwards compatibility)
    attr_reader :deficiencies_found, :other_trade_deficiencies_found, :red_tags_found

    def self.resource_url
      OBJECT_NAME
    end

    # Find a specific job by ID
    def self.find(id)
      response = ServiceTrade.client.request(:get, "#{resource_url}/#{id}")
      new(response['data'])
    end

    # Enhanced list method with comprehensive filtering and pagination
    def self.list(filters = {}, page: 1, per_page: 100)
      # Set default status to 'scheduled' if not provided and no job number is specified
      unless filters.key?(:status) || filters.key?('status') || filters.key?(:number) || filters.key?('number')
        filters[:status] = 'scheduled'
      end

      # Use the pagination from the List module
      super(filters, page: page, per_page: per_page)
    end

    # Create a new job
    def self.create(params = {})
      response = ServiceTrade.client.request(:post, resource_url, params)
      new(response['data'])
    end

    # Update an existing job
    def self.update(id, params = {})
      response = ServiceTrade.client.request(:put, "#{resource_url}/#{id}", params)
      new(response['data'])
    end

    # Update this job instance
    def update(params = {})
      self.class.update(id, params)
    end

    # Delete a job
    def self.delete(id)
      ServiceTrade.client.request(:delete, "#{resource_url}/#{id}")
      true
    end

    # Delete this job instance
    def delete
      self.class.delete(id)
    end

    # Add task responses to a job
    def add_task_responses(task_responses)
      params = { task_responses: task_responses }
      response = ServiceTrade.client.request(:post, "#{self.class.resource_url}/#{id}/taskresponses", params)
      response['data']
    end

    # Get attachments for this job
    def attachments(page: 1, per_page: 100)
      ServiceTrade::Attachment.for_job(id, page: page, per_page: per_page)
    end

    # Convenience methods for common job filtering
    def self.by_status(status, page: 1, per_page: 100)
      list({status: status}, page: page, per_page: per_page)
    end

    def self.by_customer(customer_id, page: 1, per_page: 100)
      list({customer_id: customer_id}, page: page, per_page: per_page)
    end

    def self.by_vendor(vendor_id, page: 1, per_page: 100)
      list({vendor_id: vendor_id}, page: page, per_page: per_page)
    end

    def self.by_location(location_id, page: 1, per_page: 100)
      list({location_id: location_id}, page: page, per_page: per_page)
    end

    def self.by_owner(owner_id, page: 1, per_page: 100)
      list({owner_id: owner_id}, page: page, per_page: per_page)
    end

    def self.around_location(lat, lon, radius, page: 1, per_page: 100)
      list({lat: lat, lon: lon, radius: radius}, page: page, per_page: per_page)
    end

    def self.due_between(start_timestamp, end_timestamp, page: 1, per_page: 100)
      list({due_by_begin: start_timestamp, due_by_end: end_timestamp}, page: page, per_page: per_page)
    end

    def self.completed_between(start_timestamp, end_timestamp, page: 1, per_page: 100)
      list({completed_on_begin: start_timestamp, completed_on_end: end_timestamp}, page: page, per_page: per_page)
    end

    # Check if job is completed
    def completed?
      status == 'completed'
    end

    # Check if job is canceled
    def canceled?
      status == 'canceled'
    end

    # Check if job is scheduled
    def scheduled?
      status == 'scheduled'
    end

    # Check if job is invoiced
    def invoiced?
      status == 'invoiced'
    end

    # Check if job has IVR activity open
    def ivr_open?
      ivr_open == true
    end
  end
end