module ServiceTrade
  class LibItem < BaseResource
    extend ServiceTrade::ApiOperations::Create
    extend ServiceTrade::ApiOperations::List
    extend ServiceTrade::ApiOperations::Update
    extend ServiceTrade::ApiOperations::Delete

    OBJECT_NAME = 'libitem'.freeze

    # Core library item attributes
    attr_reader :id, :uri, :name, :type, :code, :is_generic, :created, :updated

    def self.resource_url
      OBJECT_NAME
    end

    # Find a specific library item by ID
    def self.find(id)
      response = ServiceTrade.client.request(:get, "#{resource_url}/#{id}")
      new(response['data'])
    end

    # Enhanced list method with filtering and pagination
    def self.list(filters = {}, page: 1, per_page: 100)
      # Use the pagination from the List module
      super(filters, page: page, per_page: per_page)
    end

    # Create a new library item
    def self.create(params = {})
      response = ServiceTrade.client.request(:post, resource_url, params)
      new(response['data'])
    end

    # Update an existing library item
    def self.update(id, params = {})
      response = ServiceTrade.client.request(:put, "#{resource_url}/#{id}", params)
      new(response['data'])
    end

    # Update this library item instance
    def update(params = {})
      self.class.update(id, params)
    end

    # Delete a library item
    def self.delete(id)
      ServiceTrade.client.request(:delete, "#{resource_url}/#{id}")
      true
    end

    # Delete this library item instance
    def delete
      self.class.delete(id)
    end

    # Convenience methods for common library item filtering
    def self.by_type(type, page: 1, per_page: 100)
      list({type: type}, page: page, per_page: per_page)
    end

    def self.by_code(code, page: 1, per_page: 100)
      list({code: code}, page: page, per_page: per_page)
    end

    def self.by_name(name, page: 1, per_page: 100)
      list({name: name}, page: page, per_page: per_page)
    end

    def self.generic_items(page: 1, per_page: 100)
      list({is_generic: true}, page: page, per_page: per_page)
    end

    def self.non_generic_items(page: 1, per_page: 100)
      list({is_generic: false}, page: page, per_page: per_page)
    end

    # Check if library item is generic (used for ad-hoc items)
    def generic?
      is_generic == true
    end
  end
end
