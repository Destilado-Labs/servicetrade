module ServiceTrade
  class ServiceLine < BaseResource
    extend ServiceTrade::ApiOperations::List

    OBJECT_NAME = 'serviceline'.freeze

    # Service line attributes
    attr_reader :id, :name, :trade, :abbr, :icon

    def self.resource_url
      OBJECT_NAME
    end

    # Find a specific service line by ID
    def self.find(id)
      response = ServiceTrade.client.request(:get, "#{resource_url}/#{id}")
      new(response['data'])
    end
  end
end
