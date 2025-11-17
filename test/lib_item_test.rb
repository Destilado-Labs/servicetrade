# frozen_string_literal: true

require_relative "test_helper"

class LibItemTest < Test::Unit::TestCase
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

  def test_lib_item_resource_url
    assert_equal "libitem", ServiceTrade::LibItem.resource_url
  end

  def test_lib_item_attributes_exist
    lib_item = ServiceTrade::LibItem.new({
      'id' => 123,
      'uri' => '/libitem/123',
      'name' => 'Test Library Item',
      'type' => 'service',
      'code' => 'TEST-001',
      'isGeneric' => false
    })

    assert_equal 123, lib_item.id
    assert_equal '/libitem/123', lib_item.uri
    assert_equal 'Test Library Item', lib_item.name
    assert_equal 'service', lib_item.type
    assert_equal 'TEST-001', lib_item.code
    assert_equal false, lib_item.is_generic
  end

  def test_lib_item_generic_method
    generic_item = ServiceTrade::LibItem.new({'isGeneric' => true})
    assert generic_item.generic?

    non_generic_item = ServiceTrade::LibItem.new({'isGeneric' => false})
    refute non_generic_item.generic?
  end

  def test_lib_item_list_with_mocked_response
    response = {
      'data' => {
        'libItems' => [
          {
            'id' => 123,
            'name' => 'Test Item 1',
            'type' => 'service',
            'code' => 'TEST-001',
            'isGeneric' => false
          },
          {
            'id' => 456,
            'name' => 'Test Item 2',
            'type' => 'product',
            'code' => 'TEST-002',
            'isGeneric' => true
          }
        ],
        'total' => 2,
        'page' => 1
      }
    }

    stub_request(:get, /.*api\.servicetrade\.com\/api\/libitem.*/)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    lib_items_response = ServiceTrade::LibItem.list

    assert_equal 2, lib_items_response.data.length
    assert_equal 123, lib_items_response.data.first.id
    assert_equal 'Test Item 1', lib_items_response.data.first.name
    assert_equal 456, lib_items_response.data.last.id
    assert_equal 'Test Item 2', lib_items_response.data.last.name
  end

  def test_lib_item_find_with_mocked_response
    response = {
      'data' => {
        'id' => 123,
        'uri' => '/libitem/123',
        'name' => 'Test Library Item',
        'type' => 'service',
        'code' => 'TEST-001',
        'isGeneric' => false
      }
    }

    stub_request(:get, "https://api.servicetrade.com/api/libitem/123")
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    lib_item = ServiceTrade::LibItem.find(123)

    assert_equal 123, lib_item.id
    assert_equal '/libitem/123', lib_item.uri
    assert_equal 'Test Library Item', lib_item.name
    assert_equal 'service', lib_item.type
    assert_equal 'TEST-001', lib_item.code
    assert_equal false, lib_item.is_generic
  end

  def test_lib_item_create_with_mocked_response
    request_params = {
      'name' => 'New Library Item',
      'type' => 'service',
      'code' => 'NEW-001',
      'isGeneric' => false
    }

    response = {
      'data' => {
        'id' => 789,
        'uri' => '/libitem/789',
        'name' => 'New Library Item',
        'type' => 'service',
        'code' => 'NEW-001',
        'isGeneric' => false
      }
    }

    stub_request(:post, "https://api.servicetrade.com/api/libitem")
      .with(body: request_params.to_json)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    lib_item = ServiceTrade::LibItem.create(request_params)

    assert_equal 789, lib_item.id
    assert_equal 'New Library Item', lib_item.name
    assert_equal 'service', lib_item.type
    assert_equal 'NEW-001', lib_item.code
  end

  def test_lib_item_update_with_mocked_response
    request_params = {
      'name' => 'Updated Library Item'
    }

    response = {
      'data' => {
        'id' => 123,
        'uri' => '/libitem/123',
        'name' => 'Updated Library Item',
        'type' => 'service',
        'code' => 'TEST-001',
        'isGeneric' => false
      }
    }

    stub_request(:put, "https://api.servicetrade.com/api/libitem/123")
      .with(body: request_params.to_json)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    lib_item = ServiceTrade::LibItem.update(123, request_params)

    assert_equal 123, lib_item.id
    assert_equal 'Updated Library Item', lib_item.name
  end

  def test_lib_item_delete_with_mocked_response
    stub_request(:delete, "https://api.servicetrade.com/api/libitem/123")
      .to_return(status: 204)

    result = ServiceTrade::LibItem.delete(123)
    assert_equal true, result
  end

  def test_lib_item_convenience_methods
    # Test filtering methods exist
    assert_respond_to ServiceTrade::LibItem, :by_type
    assert_respond_to ServiceTrade::LibItem, :by_code
    assert_respond_to ServiceTrade::LibItem, :by_name
    assert_respond_to ServiceTrade::LibItem, :generic_items
    assert_respond_to ServiceTrade::LibItem, :non_generic_items
  end

  def test_lib_item_instance_update
    lib_item = ServiceTrade::LibItem.new({'id' => 123, 'name' => 'Original Item'})

    update_params = {'name' => 'Updated Item'}
    response = {
      'data' => {
        'id' => 123,
        'name' => 'Updated Item',
        'type' => 'service'
      }
    }

    stub_request(:put, "https://api.servicetrade.com/api/libitem/123")
      .with(body: update_params.to_json)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    updated_item = lib_item.update(update_params)
    assert_equal 'Updated Item', updated_item.name
  end

  def test_lib_item_instance_delete
    lib_item = ServiceTrade::LibItem.new({'id' => 123, 'name' => 'Item to Delete'})

    stub_request(:delete, "https://api.servicetrade.com/api/libitem/123")
      .to_return(status: 204)

    result = lib_item.delete
    assert_equal true, result
  end
end
