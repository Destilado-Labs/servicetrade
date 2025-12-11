# frozen_string_literal: true

require_relative "test_helper"

class AuthTest < Test::Unit::TestCase
  def setup
    ServiceTrade.reset!
    
    # Stub auth endpoint for successful authentication
    stub_request(:post, "https://api.servicetrade.com/api/auth")
      .with(
        body: '{"username":"test_user","password":"test_password"}',
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json'
        }
      )
      .to_return(
        status: 200,
        body: '{"sessionId": "test_session_123", "data": {"authenticated": true, "authToken": "test_token_123", "user": {"id": 1, "username": "test_user"}}}',
        headers: {'Content-Type' => 'application/json'}
      )
  end

  def teardown
    ServiceTrade.reset!
  end

  def test_token_authentication_configuration
    ServiceTrade.configure do |config|
      config.api_token = "test_api_token"
    end

    assert ServiceTrade.configured?
    assert ServiceTrade.configuration.token_auth_configured?
    refute ServiceTrade.configuration.username_password_auth_configured?
  end

  def test_username_password_authentication_configuration
    ServiceTrade.configure do |config|
      config.username = "test_user"
      config.password = "test_password"
    end

    assert ServiceTrade.configured?
    refute ServiceTrade.configuration.token_auth_configured?
    assert ServiceTrade.configuration.username_password_auth_configured?
  end

  def test_mixed_authentication_configuration_prefers_token
    ServiceTrade.configure do |config|
      config.api_token = "test_api_token"
      config.username = "test_user"
      config.password = "test_password"
    end

    assert ServiceTrade.configured?
    assert ServiceTrade.configuration.token_auth_configured?
    assert ServiceTrade.configuration.username_password_auth_configured?
  end

  def test_authenticate_with_credentials_success
    auth_response = ServiceTrade::Auth.authenticate_with_credentials("test_user", "test_password")

    assert auth_response['authenticated']
    assert_equal "test_token_123", auth_response['authToken']
    assert_equal 1, auth_response['user']['id']
    assert_equal "test_user", auth_response['user']['username']
  end

  def test_authenticate_with_credentials_failure
    stub_request(:post, "https://api.servicetrade.com/api/auth")
      .with(body: '{"username":"bad_user","password":"bad_password"}')
      .to_return(
        status: 403,
        body: '{"messages": {"error": ["Invalid credentials provided"]}, "data": {"authenticated": false, "authToken": null}}',
        headers: {'Content-Type' => 'application/json'}
      )

    error = assert_raises(ServiceTrade::AuthenticationError) do
      ServiceTrade::Auth.authenticate_with_credentials("bad_user", "bad_password")
    end

    assert_match(/Invalid credentials provided/, error.message)
    assert_match(/This usually means/, error.message)
  end

  def test_authenticate_with_oauth_tokens_success
    stub_request(:post, "https://api.servicetrade.com/api/auth/userinfo")
      .with(body: '{"id_token":"test_id_token","access_token":"test_access_token"}')
      .to_return(
        status: 200,
        body: '{"data": {"authenticated": true, "authToken": "oauth_token_456", "user": {"id": 2, "email": "test@example.com"}}}',
        headers: {'Content-Type' => 'application/json'}
      )

    auth_response = ServiceTrade::Auth.authenticate_with_oauth_tokens("test_id_token", "test_access_token")

    assert auth_response['authenticated']
    assert_equal "oauth_token_456", auth_response['authToken']
    assert_equal 2, auth_response['user']['id']
    assert_equal "test@example.com", auth_response['user']['email']
  end

  def test_authenticate_with_oauth_tokens_failure
    stub_request(:post, "https://api.servicetrade.com/api/auth/userinfo")
      .with(body: '{"id_token":"bad_token","access_token":"bad_token"}')
      .to_return(
        status: 403,
        body: '{"messages": {"error": ["invalid id_token or access_token"]}, "data": {"authenticated": false}}',
        headers: {'Content-Type' => 'application/json'}
      )

    error = assert_raises(ServiceTrade::AuthenticationError) do
      ServiceTrade::Auth.authenticate_with_oauth_tokens("bad_token", "bad_token")
    end

    assert_match(/invalid id_token or access_token/, error.message)
    assert_match(/verify your OAuth tokens/, error.message)
  end

  def test_set_api_token
    ServiceTrade::Auth.set_api_token("direct_token_789", {"id" => 3, "name" => "Test User"})

    assert ServiceTrade.configured?
    assert_equal "direct_token_789", ServiceTrade.configuration.api_token
  end

  def test_current_user_info_success
    ServiceTrade.configure do |config|
      config.api_token = "valid_token"
    end

    stub_request(:get, "https://api.servicetrade.com/api/auth")
      .to_return(
        status: 200,
        body: '{"data": {"authenticated": true, "user": {"id": 4, "name": "Current User"}}}',
        headers: {'Content-Type' => 'application/json'}
      )

    user_info = ServiceTrade::Auth.current_user_info

    assert user_info['authenticated']
    assert_equal 4, user_info['user']['id']
    assert_equal "Current User", user_info['user']['name']
  end

  def test_current_user_info_no_session
    ServiceTrade.configure do |config|
      config.api_token = "invalid_token"
    end

    stub_request(:get, "https://api.servicetrade.com/api/auth")
      .to_return(status: 404)

    error = assert_raises(ServiceTrade::AuthenticationError) do
      ServiceTrade::Auth.current_user_info
    end

    assert_match(/No active authentication session/, error.message)
  end

  def test_authenticated_check_with_valid_token
    ServiceTrade.configure do |config|
      config.api_token = "valid_token"
    end

    stub_request(:get, "https://api.servicetrade.com/api/auth")
      .to_return(
        status: 200,
        body: '{"data": {"authenticated": true}}',
        headers: {'Content-Type' => 'application/json'}
      )

    assert ServiceTrade::Auth.authenticated?
  end

  def test_authenticated_check_with_invalid_token
    ServiceTrade.configure do |config|
      config.api_token = "invalid_token"
    end

    stub_request(:get, "https://api.servicetrade.com/api/auth")
      .to_return(status: 404)

    refute ServiceTrade::Auth.authenticated?
  end

  def test_authenticated_check_unconfigured
    # No configuration
    refute ServiceTrade::Auth.authenticated?
  end

  def test_logout_success
    ServiceTrade.configure do |config|
      config.api_token = "valid_token"
    end

    stub_request(:delete, "https://api.servicetrade.com/api/auth")
      .to_return(status: 204)

    assert ServiceTrade::Auth.logout
  end

  def test_logout_no_session
    ServiceTrade.configure do |config|
      config.api_token = "valid_token"
    end

    stub_request(:delete, "https://api.servicetrade.com/api/auth")
      .to_return(status: 404)

    # Should still return true even if no session exists
    assert ServiceTrade::Auth.logout
  end

  def test_client_uses_token_authentication_header
    ServiceTrade.configure do |config|
      config.api_token = "test_token_header"
    end

    # Mock a simple API call to verify cookie
    stub_request(:get, "https://api.servicetrade.com/api/job?page=1&per_page=100&status=scheduled")
      .with(headers: {'Cookie' => 'PHPSESSID=test_token_header'})
      .to_return(
        status: 200,
        body: '{"data": {"jobs": []}}',
        headers: {'Content-Type' => 'application/json'}
      )

    ServiceTrade::Job.list
    
    # If we get here without an error, the cookie was sent correctly
    assert true
  end

  def test_client_uses_session_authentication_header
    ServiceTrade.configure do |config|
      config.username = "test_user"
      config.password = "test_password"
    end

    # Mock a simple API call to verify session cookie is used
    stub_request(:get, "https://api.servicetrade.com/api/job?page=1&per_page=100&status=scheduled")
      .with(headers: {'Cookie' => 'PHPSESSID=test_token_123'})
      .to_return(
        status: 200,
        body: '{"data": {"jobs": []}}',
        headers: {'Content-Type' => 'application/json'}
      )

    ServiceTrade::Job.list
    
    # If we get here without an error, the session cookie was sent correctly
    assert true
  end

  def test_validation_allows_token_auth_without_username_password
    ServiceTrade.configure do |config|
      config.api_token = "test_token"
      # No username/password configured
    end

    # Should not raise an error
    assert_nothing_raised do
      ServiceTrade.validate_configuration!
    end
  end

  def test_enhanced_configuration_error_message_shows_both_options
    # No configuration at all
    error = assert_raises(ServiceTrade::ConfigurationError) do
      ServiceTrade.validate_configuration!
    end

    assert_match(/Option 1 - API Token Authentication/, error.message)
    assert_match(/Option 2 - Username\/Password Authentication/, error.message)
    assert_match(/environment variables/, error.message)
    assert_match(/authenticate_with_credentials/, error.message)
  end

  def test_auth_methods_exist
    assert_respond_to ServiceTrade::Auth, :authenticate_with_credentials
    assert_respond_to ServiceTrade::Auth, :authenticate_with_oauth_tokens
    assert_respond_to ServiceTrade::Auth, :current_user_info
    assert_respond_to ServiceTrade::Auth, :logout
    assert_respond_to ServiceTrade::Auth, :set_api_token
    assert_respond_to ServiceTrade::Auth, :authenticated?
  end

  def test_instance_authenticate_with_username_password
    ServiceTrade.configure do |config|
      config.username = "test_user"
      config.password = "test_password"
    end

    # The auth instance should use the configured credentials
    auth_instance = ServiceTrade.auth
    session_id = auth_instance.authenticate
    
    # Should return session ID
    assert_equal "test_session_123", session_id
    
    # Should store the auth token in instance variables
    assert_equal "test_token_123", auth_instance.auth_token
    
    # Should update the configuration with the API token for future requests
    assert_equal "test_token_123", ServiceTrade.configuration.api_token
    
    # Should now be token-auth configured
    assert ServiceTrade.configuration.token_auth_configured?
  end

  def test_instance_authenticate_updates_configuration_for_api_token_usage
    ServiceTrade.configure do |config|
      config.username = "test_user" 
      config.password = "test_password"
    end

    # Initially should be username/password configured
    assert ServiceTrade.configuration.username_password_auth_configured?
    refute ServiceTrade.configuration.token_auth_configured?
    
    # After authentication, should switch to token auth
    ServiceTrade.auth.authenticate
    
    assert ServiceTrade.configuration.token_auth_configured?
    assert ServiceTrade.configuration.username_password_auth_configured? # Both should be true
  end
end