# frozen_string_literal: true

require_relative "test_helper"

class JobItemTest < Test::Unit::TestCase
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

  def test_job_item_resource_url
    assert_equal "jobitem", ServiceTrade::JobItem.resource_url
  end

  def test_job_item_attributes_exist
    job_item = ServiceTrade::JobItem.new({
      'id' => 456,
      'uri' => '/jobitem/456',
      'description' => 'HVAC Filter Replacement',
      'cost' => 125.50,
      'usedOn' => 1634567890,
      'quantity' => 2,
      'unitPrice' => 62.75,
      'total' => 125.50,
      'type' => 'material',
      'notes' => 'Premium MERV 13 filter'
    })

    assert_equal 456, job_item.id
    assert_equal '/jobitem/456', job_item.uri
    assert_equal 'HVAC Filter Replacement', job_item.description
    assert_equal 125.50, job_item.cost
    assert_equal 1634567890, job_item.used_on
    assert_equal 2, job_item.quantity
    assert_equal 62.75, job_item.unit_price
    assert_equal 125.50, job_item.total
    assert_equal 'material', job_item.type
    assert_equal 'Premium MERV 13 filter', job_item.notes
  end

  def test_job_item_with_related_objects
    job_item = ServiceTrade::JobItem.new({
      'id' => 456,
      'description' => 'Test Item',
      'job' => {
        'id' => 789,
        'name' => 'Service Call'
      },
      'libItem' => {
        'id' => 123,
        'name' => 'Standard Filter'
      },
      'vendor' => {
        'id' => 999,
        'name' => 'HVAC Supplies Inc'
      }
    })

    assert_equal({'id' => 789, 'name' => 'Service Call'}, job_item.job)
    assert_equal({'id' => 123, 'name' => 'Standard Filter'}, job_item.lib_item)
    assert_equal({'id' => 999, 'name' => 'HVAC Supplies Inc'}, job_item.vendor)
  end

  def test_calculate_total_method
    # Test with quantity and unit_price
    job_item = ServiceTrade::JobItem.new({
      'quantity' => 3,
      'unitPrice' => 25.00
    })
    assert_equal 75.00, job_item.calculate_total

    # Test without quantity
    job_item_no_qty = ServiceTrade::JobItem.new({
      'unitPrice' => 25.00
    })
    assert_nil job_item_no_qty.calculate_total

    # Test without unit_price
    job_item_no_price = ServiceTrade::JobItem.new({
      'quantity' => 3
    })
    assert_nil job_item_no_price.calculate_total
  end

  def test_total_cost_method
    # Test when total is provided
    job_item_with_total = ServiceTrade::JobItem.new({
      'total' => 100.00,
      'cost' => 90.00,
      'quantity' => 2,
      'unitPrice' => 45.00
    })
    assert_equal 100.00, job_item_with_total.total_cost

    # Test when cost is provided but not total
    job_item_with_cost = ServiceTrade::JobItem.new({
      'cost' => 90.00,
      'quantity' => 2,
      'unitPrice' => 45.00
    })
    assert_equal 90.00, job_item_with_cost.total_cost

    # Test when calculating from quantity and unit_price
    job_item_calculated = ServiceTrade::JobItem.new({
      'quantity' => 2,
      'unitPrice' => 45.00
    })
    assert_equal 90.00, job_item_calculated.total_cost

    # Test when no pricing info available
    job_item_no_price = ServiceTrade::JobItem.new({'description' => 'Test'})
    assert_nil job_item_no_price.total_cost
  end

  def test_job_item_list_with_mocked_response
    response = {
      'data' => {
        'jobItems' => [
          {
            'id' => 456,
            'description' => 'Filter Replacement',
            'cost' => 125.50,
            'usedOn' => 1634567890
          },
          {
            'id' => 789,
            'description' => 'Labor - Installation',
            'cost' => 250.00,
            'usedOn' => 1634567890
          }
        ],
        'total' => 2,
        'page' => 1
      }
    }

    stub_request(:get, /.*api\.servicetrade\.com\/api\/jobitem.*/)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    job_items_response = ServiceTrade::JobItem.list

    assert_equal 2, job_items_response.data.length
    assert_equal 456, job_items_response.data.first.id
    assert_equal 'Filter Replacement', job_items_response.data.first.description
    assert_equal 789, job_items_response.data.last.id
    assert_equal 'Labor - Installation', job_items_response.data.last.description
  end

  def test_job_item_find_with_mocked_response
    response = {
      'data' => {
        'id' => 456,
        'uri' => '/jobitem/456',
        'description' => 'HVAC Filter',
        'cost' => 125.50,
        'usedOn' => 1634567890,
        'quantity' => 2,
        'unitPrice' => 62.75
      }
    }

    stub_request(:get, "https://api.servicetrade.com/api/jobitem/456")
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    job_item = ServiceTrade::JobItem.find(456)

    assert_equal 456, job_item.id
    assert_equal '/jobitem/456', job_item.uri
    assert_equal 'HVAC Filter', job_item.description
    assert_equal 125.50, job_item.cost
    assert_equal 1634567890, job_item.used_on
  end

  def test_job_item_create_with_mocked_response
    request_params = {
      'jobId' => 789,
      'description' => 'New Filter',
      'cost' => 75.00,
      'quantity' => 1,
      'usedOn' => 1634567890
    }

    response = {
      'data' => {
        'id' => 999,
        'uri' => '/jobitem/999',
        'description' => 'New Filter',
        'cost' => 75.00,
        'quantity' => 1,
        'usedOn' => 1634567890
      }
    }

    stub_request(:post, "https://api.servicetrade.com/api/jobitem")
      .with(body: request_params.to_json)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    job_item = ServiceTrade::JobItem.create(request_params)

    assert_equal 999, job_item.id
    assert_equal 'New Filter', job_item.description
    assert_equal 75.00, job_item.cost
  end

  def test_job_item_update_with_mocked_response
    request_params = {
      'cost' => 150.00,
      'description' => 'Updated Filter'
    }

    response = {
      'data' => {
        'id' => 456,
        'uri' => '/jobitem/456',
        'description' => 'Updated Filter',
        'cost' => 150.00
      }
    }

    stub_request(:put, "https://api.servicetrade.com/api/jobitem/456")
      .with(body: request_params.to_json)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    job_item = ServiceTrade::JobItem.update(456, request_params)

    assert_equal 456, job_item.id
    assert_equal 'Updated Filter', job_item.description
    assert_equal 150.00, job_item.cost
  end

  def test_job_item_delete_with_mocked_response
    stub_request(:delete, "https://api.servicetrade.com/api/jobitem/456")
      .to_return(status: 204)

    result = ServiceTrade::JobItem.delete(456)
    assert_equal true, result
  end

  def test_job_item_convenience_methods
    # Test filtering methods exist
    assert_respond_to ServiceTrade::JobItem, :by_job
    assert_respond_to ServiceTrade::JobItem, :by_lib_item
    assert_respond_to ServiceTrade::JobItem, :used_on_date
    assert_respond_to ServiceTrade::JobItem, :used_between
  end

  def test_job_item_instance_update
    job_item = ServiceTrade::JobItem.new({'id' => 456, 'description' => 'Original Item'})

    update_params = {'description' => 'Updated Item'}
    response = {
      'data' => {
        'id' => 456,
        'description' => 'Updated Item',
        'cost' => 100.00
      }
    }

    stub_request(:put, "https://api.servicetrade.com/api/jobitem/456")
      .with(body: update_params.to_json)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    updated_item = job_item.update(update_params)
    assert_equal 'Updated Item', updated_item.description
  end

  def test_job_item_instance_delete
    job_item = ServiceTrade::JobItem.new({'id' => 456, 'description' => 'Item to Delete'})

    stub_request(:delete, "https://api.servicetrade.com/api/jobitem/456")
      .to_return(status: 204)

    result = job_item.delete
    assert_equal true, result
  end

  def test_job_item_by_job_filter
    response = {
      'data' => {
        'jobItems' => [
          {'id' => 1, 'description' => 'Item 1'},
          {'id' => 2, 'description' => 'Item 2'}
        ],
        'total' => 2,
        'page' => 1
      }
    }

    stub_request(:get, /.*api\.servicetrade\.com\/api\/jobitem.*job_id=789.*/)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    job_items = ServiceTrade::JobItem.by_job(789)
    assert_kind_of ServiceTrade::ListResponse, job_items
  end
end
