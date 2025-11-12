# frozen_string_literal: true

require_relative "test_helper"

class WebhookTest < Test::Unit::TestCase
  def setup
    ServiceTrade.reset!
    ServiceTrade.configure do |config|
      config.username = "test_user"
      config.password = "test_password"
    end

    # Stub auth endpoint
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
        body: '{"sessionId": "test_session_123", "data": {"authenticated": true, "authToken": "test_session_123", "user": {"id": 1, "username": "test_user"}}}',
        headers: {'Content-Type' => 'application/json'}
      )
  end

  def test_webhook_resource_url
    assert_equal "webhook", ServiceTrade::Webhook.resource_url
  end

  def test_webhook_attributes_exist
    webhook = ServiceTrade::Webhook.new({
      'id' => 123,
      'uri' => '/webhook/123',
      'hookUrl' => 'https://example.com/webhook',
      'enabled' => true,
      'confirmed' => true,
      'includeChangesets' => false,
      'entityEvents' => [
        {'entityType' => 3, 'eventType' => 'created'},
        {'entityType' => 3, 'eventType' => 'updated'}
      ]
    })

    assert_equal 123, webhook.id
    assert_equal '/webhook/123', webhook.uri
    assert_equal 'https://example.com/webhook', webhook.hook_url
    assert_equal true, webhook.enabled
    assert_equal true, webhook.confirmed
    assert_equal false, webhook.include_changesets
    assert_equal 2, webhook.entity_events.length
  end

  def test_webhook_status_methods
    webhook = ServiceTrade::Webhook.new({'enabled' => true, 'confirmed' => true, 'includeChangesets' => false})
    assert webhook.enabled?
    assert webhook.confirmed?
    refute webhook.include_changesets?

    webhook = ServiceTrade::Webhook.new({'enabled' => false, 'confirmed' => false, 'includeChangesets' => true})
    refute webhook.enabled?
    refute webhook.confirmed?
    assert webhook.include_changesets?
  end

  def test_webhook_list_with_mocked_response
    response = {
      'data' => {
        'webhooks' => [
          {
            'id' => 123,
            'hookUrl' => 'https://example.com/webhook1',
            'enabled' => true
          },
          {
            'id' => 456,
            'hookUrl' => 'https://example.com/webhook2',
            'enabled' => false
          }
        ],
        'total' => 2,
        'page' => 1
      }
    }

    stub_request(:get, /.*api\.servicetrade\.com\/api\/webhook.*/)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    webhooks_response = ServiceTrade::Webhook.list

    assert_equal 2, webhooks_response.data.length
    assert_equal 123, webhooks_response.data.first.id
    assert_equal 'https://example.com/webhook1', webhooks_response.data.first.hook_url
    assert_equal 456, webhooks_response.data.last.id
    assert_equal 'https://example.com/webhook2', webhooks_response.data.last.hook_url
  end

  def test_webhook_find_with_mocked_response
    response = {
      'data' => {
        'id' => 123,
        'uri' => '/webhook/123',
        'hookUrl' => 'https://example.com/webhook',
        'enabled' => true,
        'confirmed' => true,
        'includeChangesets' => false,
        'entityEvents' => [
          {'entityType' => 3, 'eventType' => 'created'}
        ]
      }
    }

    stub_request(:get, "https://api.servicetrade.com/api/webhook/123")
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    webhook = ServiceTrade::Webhook.find(123)

    assert_equal 123, webhook.id
    assert_equal '/webhook/123', webhook.uri
    assert_equal 'https://example.com/webhook', webhook.hook_url
    assert_equal true, webhook.enabled
    assert_equal true, webhook.confirmed
    assert_equal false, webhook.include_changesets
    assert_equal 1, webhook.entity_events.length
  end

  def test_webhook_create_with_mocked_response
    request_params = {
      'hookUrl' => 'https://example.com/new-webhook',
      'enabled' => true,
      'includeChangesets' => false,
      'entityEvents' => [
        {'entityType' => 3, 'eventType' => 'created'},
        {'entityType' => 3, 'eventType' => 'updated'}
      ]
    }

    response = {
      'data' => {
        'id' => 789,
        'uri' => '/webhook/789',
        'hookUrl' => 'https://example.com/new-webhook',
        'enabled' => true,
        'confirmed' => false,
        'includeChangesets' => false,
        'entityEvents' => [
          {'entityType' => 3, 'eventType' => 'created'},
          {'entityType' => 3, 'eventType' => 'updated'}
        ]
      }
    }

    stub_request(:post, "https://api.servicetrade.com/api/webhook")
      .with(body: request_params.to_json)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    webhook = ServiceTrade::Webhook.create(request_params)

    assert_equal 789, webhook.id
    assert_equal 'https://example.com/new-webhook', webhook.hook_url
    assert_equal true, webhook.enabled
    assert_equal false, webhook.confirmed
    assert_equal 2, webhook.entity_events.length
  end

  def test_webhook_update_with_mocked_response
    request_params = {
      'enabled' => false
    }

    response = {
      'data' => {
        'id' => 123,
        'hookUrl' => 'https://example.com/webhook',
        'enabled' => false,
        'confirmed' => true
      }
    }

    stub_request(:put, "https://api.servicetrade.com/api/webhook/123")
      .with(body: request_params.to_json)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    webhook = ServiceTrade::Webhook.update(123, request_params)

    assert_equal 123, webhook.id
    assert_equal false, webhook.enabled
  end

  def test_webhook_delete_with_mocked_response
    stub_request(:delete, "https://api.servicetrade.com/api/webhook/123")
      .to_return(
        status: 200,
        body: '{"success": true}',
        headers: {'Content-Type' => 'application/json'}
      )

    result = ServiceTrade::Webhook.delete(123)

    assert_equal true, result
  end

  def test_webhook_instance_update
    webhook = ServiceTrade::Webhook.new({'id' => 123})

    request_params = {'enabled' => false}
    response = {
      'data' => {
        'id' => 123,
        'enabled' => false
      }
    }

    stub_request(:put, "https://api.servicetrade.com/api/webhook/123")
      .with(body: request_params.to_json)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    updated_webhook = webhook.update(request_params)
    assert_equal false, updated_webhook.enabled
  end

  def test_webhook_instance_delete
    webhook = ServiceTrade::Webhook.new({'id' => 123})

    stub_request(:delete, "https://api.servicetrade.com/api/webhook/123")
      .to_return(
        status: 200,
        body: '{"success": true}',
        headers: {'Content-Type' => 'application/json'}
      )

    result = webhook.delete
    assert_equal true, result
  end
end
