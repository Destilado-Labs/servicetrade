# frozen_string_literal: true

require_relative "servicetrade/version"
require_relative "servicetrade/configuration"
require_relative "servicetrade/client"
require_relative "servicetrade/auth"
require_relative "servicetrade/errors"

# API Operations
require_relative "servicetrade/api_operations/create"
require_relative "servicetrade/api_operations/list"
require_relative "servicetrade/api_operations/update"
require_relative "servicetrade/api_operations/delete"

# Resources
require_relative "servicetrade/resources/base_resource"
require_relative "servicetrade/resources/job"
require_relative "servicetrade/resources/appointment"
require_relative "servicetrade/resources/location"
require_relative "servicetrade/resources/region"
require_relative "servicetrade/resources/company"
require_relative "servicetrade/resources/contact"
require_relative "servicetrade/resources/external_id"
require_relative "servicetrade/resources/service_request"
require_relative "servicetrade/resources/service_line"
require_relative "servicetrade/resources/webhook"

require "net/http"
require "json"

module ServiceTrade
  class << self
    attr_accessor :configuration, :auth_instance, :client_instance
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
    configuration
  end

  def self.auth
    @auth_instance ||= Auth.new
  end

  def self.client
    @client_instance ||= Client.new
  end

  def self.api_base
    "https://api.servicetrade.com/api"
  end

  # Check if ServiceTrade has been configured with valid credentials
  def self.configured?
    configuration&.configured? || false
  end
  
  # Validate current configuration and raise error if invalid
  def self.validate_configuration!
    # Initialize configuration if nil so we can use the enhanced error message
    self.configuration ||= Configuration.new
    configuration.validate!
  end

  # Reset all instances (useful for testing)
  def self.reset!
    @configuration = nil
    @auth_instance = nil
    @client_instance = nil
  end
end