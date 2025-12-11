module ServiceTrade
  class Comment < BaseResource
    extend ServiceTrade::ApiOperations::List

    OBJECT_NAME = 'comment'.freeze

    # Core comment attributes
    attr_reader :id, :uri, :comment, :visibility, :created, :updated

    # Related objects
    attr_reader :created_by, :job

    def self.resource_url
      OBJECT_NAME
    end

    # Find a specific comment by ID
    def self.find(id)
      response = ServiceTrade.client.request(:get, "#{resource_url}/#{id}")
      new(response['data'])
    end

    # List method with filtering support
    def self.list(filters = {}, page: 1, per_page: 100)
      super(filters, page: page, per_page: per_page)
    end

    # Get comments for a specific job
    def self.for_job(job_id, page: 1, per_page: 100)
      params = {
        page: page,
        per_page: per_page
      }
      response = ServiceTrade.client.request(:get, "job/#{job_id}/comment", params, {})
      ListResponse.new(response, self)
    end

    # Create a comment for a specific job
    # @param job_id [Integer] The ID of the job to add the comment to
    # @param params [Hash] Comment parameters
    # @option params [String] :comment The comment text (required)
    # @option params [Integer] :createdBy The ID of the user creating the comment (required)
    # @option params [String] :visibility The visibility level (optional)
    def self.create_for_job(job_id, params = {})
      response = ServiceTrade.client.request(:post, "job/#{job_id}/comment", params)
      new(response['data'])
    end
  end
end
