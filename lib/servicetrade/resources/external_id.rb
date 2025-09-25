# frozen_string_literal: true

module ServiceTrade
  # The ExternalId resource is used to associate ServiceTrade entities with external identifiers.
  # It can return and modify external identifiers for a given entity, or it can return an entity
  # for a given external identifier. Supported entity types: asset, company, contact, contract,
  # deficiency, location, job, jobitem, libitem, quote, user
  class ExternalId < BaseResource
    OBJECT_NAME = "externalid"

    # ExternalId attributes
    attr_reader :value

    # Valid entity types for external IDs
    VALID_ENTITY_TYPES = %w[
      asset company contact contract deficiency location
      job jobitem libitem quote user
    ].freeze

    def self.resource_url
      OBJECT_NAME
    end

    # Get all external IDs for a specific entity
    # GET /externalid/{entity_type}/{entity_id}
    def self.get_all(entity_type, entity_id)
      validate_entity_type!(entity_type)
      response = ServiceTrade.client.request(:get, "#{resource_url}/#{entity_type}/#{entity_id}")
      response["data"]["values"]
    end

    # Get external ID for a specific entity and system
    # GET /externalid/{entity_type}/{entity_id}/{external_system}
    def self.get(entity_type, entity_id, external_system)
      validate_entity_type!(entity_type)
      response = ServiceTrade.client.request(:get, "#{resource_url}/#{entity_type}/#{entity_id}/#{external_system}")
      response["data"]["value"]
    end

    # Get entity by external ID
    # GET /externalid/{entity_type}/{external_system}/{value}
    def self.find_entity(entity_type, external_system, value)
      validate_entity_type!(entity_type)
      response = ServiceTrade.client.request(:get, "#{resource_url}/#{entity_type}/#{external_system}/#{value}")
      response["data"]
    end

    # Set external ID for an entity (create or update)
    # POST /externalid/{entity_type}/{entity_id}/{external_system}
    def self.set(entity_type, entity_id, external_system, params = {})
      validate_entity_type!(entity_type)
      response = ServiceTrade.client.request(
        :post, "#{resource_url}/#{entity_type}/#{entity_id}/#{external_system}", params, {}
      )
      response["data"]["value"]
    end

    # Update external ID for an entity
    # PUT /externalid/{entity_type}/{entity_id}/{external_system}
    def self.update_external_id(entity_type, entity_id, external_system, params = {})
      validate_entity_type!(entity_type)
      response = ServiceTrade.client.request(
        :put, "#{resource_url}/#{entity_type}/#{entity_id}/#{external_system}", params, {}
      )
      response["data"]["value"]
    end

    # Remove external ID (by setting empty value)
    def self.remove(entity_type, entity_id, external_system)
      validate_entity_type!(entity_type)
      response = ServiceTrade.client.request(
        :put, "#{resource_url}/#{entity_type}/#{entity_id}/#{external_system}", { value: "" }, {}
      )
      response["data"]["value"]
    end

    class << self
      private def validate_entity_type!(entity_type)
        return if VALID_ENTITY_TYPES.include?(entity_type.to_s)

        raise ArgumentError, "Invalid entity type '#{entity_type}'. Must be one of: #{VALID_ENTITY_TYPES.join(', ')}"
      end
    end
  end
end
