module ServiceTrade
  class Webhook < BaseResource
    extend ServiceTrade::ApiOperations::Create
    extend ServiceTrade::ApiOperations::List
    extend ServiceTrade::ApiOperations::Update
    extend ServiceTrade::ApiOperations::Delete

    OBJECT_NAME = 'webhook'.freeze

    # Core webhook attributes
    attr_reader :id, :uri, :hook_url, :enabled, :confirmed,
                :include_changesets, :entity_events, :created, :updated

    def self.resource_url
      OBJECT_NAME
    end

    # Find a specific webhook by ID
    def self.find(id)
      response = ServiceTrade.client.request(:get, "#{resource_url}/#{id}")
      new(response['data'])
    end

    # List all webhooks with pagination
    def self.list(filters = {}, page: 1, per_page: 100)
      super(filters, page: page, per_page: per_page)
    end

    # Create a new webhook
    def self.create(params = {})
      response = ServiceTrade.client.request(:post, resource_url, params)
      new(response['data'])
    end

    # Update an existing webhook
    def self.update(id, params = {})
      response = ServiceTrade.client.request(:put, "#{resource_url}/#{id}", params)
      new(response['data'])
    end

    # Update this webhook instance
    def update(params = {})
      self.class.update(id, params)
    end

    # Delete a webhook
    def self.delete(id)
      ServiceTrade.client.request(:delete, "#{resource_url}/#{id}")
      true
    end

    # Delete this webhook instance
    def delete
      self.class.delete(id)
    end

    # Check if webhook is enabled
    def enabled?
      enabled == true
    end

    # Check if webhook is confirmed
    def confirmed?
      confirmed == true
    end

    # Check if webhook includes changesets
    def include_changesets?
      include_changesets == true
    end
  end
end
