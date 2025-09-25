# frozen_string_literal: true

require_relative "test_helper"

class ExternalIdTest < Test::Unit::TestCase
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

  def test_external_id_resource_url
    assert_equal "externalid", ServiceTrade::ExternalId.resource_url
  end

  def test_valid_entity_types
    expected_types = %w[asset company contact contract deficiency location job jobitem libitem quote user]
    assert_equal expected_types, ServiceTrade::ExternalId::VALID_ENTITY_TYPES
  end

  def test_get_all_external_ids
    stub_request(:get, "https://api.servicetrade.com/api/externalid/location/123")
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .to_return(
        status: 200,
        body: '{"data": {"values": {"system_name": "S1-123", "other_system": "Loc543"}}}',
        headers: {'Content-Type' => 'application/json'}
      )

    external_ids = ServiceTrade::ExternalId.get_all('location', 123)
    assert_equal({"system_name" => "S1-123", "other_system" => "Loc543"}, external_ids)
  end

  def test_get_specific_external_id
    stub_request(:get, "https://api.servicetrade.com/api/externalid/location/123/system_name")
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .to_return(
        status: 200,
        body: '{"data": {"value": "S1-123"}}',
        headers: {'Content-Type' => 'application/json'}
      )

    value = ServiceTrade::ExternalId.get('location', 123, 'system_name')
    assert_equal "S1-123", value
  end

  def test_find_entity_by_external_id
    stub_request(:get, "https://api.servicetrade.com/api/externalid/location/system_name/S1-123")
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .to_return(
        status: 200,
        body: '{"data": {"id": 820, "uri": "https://api.servicetrade.com/api/location/820", "name": "Burger Bistro", "externalIds": {"system_name": "S1-123"}}}',
        headers: {'Content-Type' => 'application/json'}
      )

    entity = ServiceTrade::ExternalId.find_entity('location', 'system_name', 'S1-123')
    assert_equal 820, entity['id']
    assert_equal "Burger Bistro", entity['name']
    assert_equal({"system_name" => "S1-123"}, entity['externalIds'])
  end

  def test_set_external_id_with_post
    stub_request(:post, "https://api.servicetrade.com/api/externalid/location/123/system_name")
      .with(
        body: '{"value":"S1-NewId123"}',
        headers: {
          'Cookie' => 'PHPSESSID=test_session_123',
          'Content-Type' => 'application/json'
        }
      )
      .to_return(
        status: 200,
        body: '{"data": {"value": "S1-NewId123"}}',
        headers: {'Content-Type' => 'application/json'}
      )

    value = ServiceTrade::ExternalId.set('location', 123, 'system_name', {value: 'S1-NewId123'})
    assert_equal "S1-NewId123", value
  end

  def test_update_external_id_with_put
    stub_request(:put, "https://api.servicetrade.com/api/externalid/location/123/system_name")
      .with(
        body: '{"value":"S1-UpdatedId"}',
        headers: {
          'Cookie' => 'PHPSESSID=test_session_123',
          'Content-Type' => 'application/json'
        }
      )
      .to_return(
        status: 200,
        body: '{"data": {"value": "S1-UpdatedId"}}',
        headers: {'Content-Type' => 'application/json'}
      )

    value = ServiceTrade::ExternalId.update_external_id('location', 123, 'system_name', {value: 'S1-UpdatedId'})
    assert_equal "S1-UpdatedId", value
  end

  def test_remove_external_id
    stub_request(:put, "https://api.servicetrade.com/api/externalid/location/123/system_name")
      .with(
        body: '{"value":""}',
        headers: {
          'Cookie' => 'PHPSESSID=test_session_123',
          'Content-Type' => 'application/json'
        }
      )
      .to_return(
        status: 200,
        body: '{"data": {"value": ""}}',
        headers: {'Content-Type' => 'application/json'}
      )

    value = ServiceTrade::ExternalId.remove('location', 123, 'system_name')
    assert_equal "", value
  end

  def test_invalid_entity_type_raises_error
    assert_raises(ArgumentError) do
      ServiceTrade::ExternalId.get_all('invalid_entity', 123)
    end

    assert_raises(ArgumentError) do
      ServiceTrade::ExternalId.get('invalid_entity', 123, 'system_name')
    end

    assert_raises(ArgumentError) do
      ServiceTrade::ExternalId.find_entity('invalid_entity', 'system_name', 'value')
    end

    assert_raises(ArgumentError) do
      ServiceTrade::ExternalId.set('invalid_entity', 123, 'system_name', {value: 'test'})
    end

    assert_raises(ArgumentError) do
      ServiceTrade::ExternalId.update_external_id('invalid_entity', 123, 'system_name', {value: 'test'})
    end

    assert_raises(ArgumentError) do
      ServiceTrade::ExternalId.remove('invalid_entity', 123, 'system_name')
    end
  end

  def test_entity_type_validation_with_symbols
    # Should work with symbol entity types
    stub_request(:get, "https://api.servicetrade.com/api/externalid/location/123")
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .to_return(
        status: 200,
        body: '{"data": {"values": {"system_name": "S1-123"}}}',
        headers: {'Content-Type' => 'application/json'}
      )

    external_ids = ServiceTrade::ExternalId.get_all(:location, 123)
    assert_equal({"system_name" => "S1-123"}, external_ids)
  end

  def test_works_with_all_valid_entity_types
    ServiceTrade::ExternalId::VALID_ENTITY_TYPES.each do |entity_type|
      stub_request(:get, "https://api.servicetrade.com/api/externalid/#{entity_type}/123")
        .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
        .to_return(
          status: 200,
          body: '{"data": {"values": {"system_name": "test_value"}}}',
          headers: {'Content-Type' => 'application/json'}
        )

      assert_nothing_raised do
        ServiceTrade::ExternalId.get_all(entity_type, 123)
      end
    end
  end
end