# frozen_string_literal: true

module ServiceTrade
  # The ServiceRequest resource represents requests for services that can be associated with
  # jobs, appointments, and assets. Service requests track work to be done and can have
  # various statuses throughout their lifecycle.
  class ServiceRequest < BaseResource
    extend ServiceTrade::ApiOperations::Create
    extend ServiceTrade::ApiOperations::List
    extend ServiceTrade::ApiOperations::Update
    extend ServiceTrade::ApiOperations::Delete

    OBJECT_NAME = "servicerequest"

    # Core service request attributes
    attr_reader :id, :uri, :description, :status, :completion_status,
                :estimated_price, :duration, :window_start, :window_end,
                :created, :updated

    # Related objects
    attr_reader :job, :appointment, :asset, :service_line, :location,
                :vendor, :customer, :assigned_user

    # Service request statuses
    VALID_STATUSES = %w[open in_progress closed void canceled].freeze

    def self.resource_url
      OBJECT_NAME
    end

    # Find a specific service request by ID
    def self.find(id)
      response = ServiceTrade.client.request(:get, "#{resource_url}/#{id}")
      new(response["data"])
    end

    # Enhanced list method with comprehensive filtering and pagination
    def self.list(filters = {}, page: 1, per_page: 100)
      # Use the pagination from the List module
      super(filters, page: page, per_page: per_page)
    end

    # Create a new service request
    def self.create(params = {})
      response = ServiceTrade.client.request(:post, resource_url, params, {})
      new(response["data"])
    end

    # Update an existing service request
    def self.update(id, params = {})
      response = ServiceTrade.client.request(:put, "#{resource_url}/#{id}", params, {})
      new(response["data"])
    end

    # Update this service request instance
    def update(params = {})
      self.class.update(id, params)
    end

    # Delete a service request
    def self.delete(id)
      ServiceTrade.client.request(:delete, "#{resource_url}/#{id}")
      true
    end

    # Delete this service request instance
    def delete
      self.class.delete(id)
    end

    # Convenience methods for common service request filtering
    def self.by_job(job_id, page: 1, per_page: 100)
      list({ job_id: job_id }, page: page, per_page: per_page)
    end

    def self.by_location(location_id, page: 1, per_page: 100)
      list({ location_id: location_id }, page: page, per_page: per_page)
    end

    def self.by_status(status, page: 1, per_page: 100)
      list({ status: status }, page: page, per_page: per_page)
    end

    def self.by_appointment(appointment_id, page: 1, per_page: 100)
      list({ appointment_id: appointment_id }, page: page, per_page: per_page)
    end

    def self.by_service_line(service_line_ids, page: 1, per_page: 100)
      service_line_ids = Array(service_line_ids).join(",") if service_line_ids.is_a?(Array)
      list({ service_line_ids: service_line_ids }, page: page, per_page: per_page)
    end

    def self.by_asset(asset_id, page: 1, per_page: 100)
      list({ asset_id: asset_id }, page: page, per_page: per_page)
    end

    # Status filtering convenience methods
    def self.open_requests(page: 1, per_page: 100)
      by_status("open", page: page, per_page: per_page)
    end

    def self.in_progress_requests(page: 1, per_page: 100)
      by_status("in_progress", page: page, per_page: per_page)
    end

    def self.closed_requests(page: 1, per_page: 100)
      by_status("closed", page: page, per_page: per_page)
    end

    def self.canceled_requests(page: 1, per_page: 100)
      by_status("canceled", page: page, per_page: per_page)
    end

    def self.void_requests(page: 1, per_page: 100)
      by_status("void", page: page, per_page: per_page)
    end

    # Status check methods
    def open?
      status == "open"
    end

    def in_progress?
      status == "in_progress"
    end

    def closed?
      status == "closed"
    end

    def canceled?
      status == "canceled"
    end

    def void?
      status == "void"
    end

    # Check if service request has an estimated price
    def estimated_price?
      !estimated_price.nil? && estimated_price > 0
    end

    # Check if service request has a time window
    def time_window?
      !window_start.nil? && !window_end.nil?
    end

    # Check if service request is associated with a job
    def associated_with_job?
      !job.nil? && !job["id"].nil?
    end

    # Check if service request is associated with an appointment
    def associated_with_appointment?
      !appointment.nil? && !appointment["id"].nil?
    end

    # Check if service request is associated with an asset
    def associated_with_asset?
      !asset.nil? && !asset["id"].nil?
    end
  end
end
