# frozen_string_literal: true

require_relative "test_helper"

class ServiceRequestTest < Test::Unit::TestCase
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

  def test_service_request_resource_url
    assert_equal "servicerequest", ServiceTrade::ServiceRequest.resource_url
  end

  def test_service_request_valid_statuses
    expected_statuses = %w[open in_progress closed void canceled]
    assert_equal expected_statuses, ServiceTrade::ServiceRequest::VALID_STATUSES
  end

  def test_service_request_attributes_exist
    service_request = ServiceTrade::ServiceRequest.new({
      'id' => 456,
      'uri' => 'https://api.servicetrade.com/api/servicerequest/456',
      'description' => 'Fix broken HVAC unit',
      'status' => 'open',
      'completionStatus' => 'pending',
      'estimatedPrice' => 250.00,
      'duration' => 120,
      'windowStart' => 1609459200,
      'windowEnd' => 1609466400,
      'created' => 1609459000,
      'updated' => 1609459100,
      'job' => {
        'id' => 123,
        'uri' => 'https://api.servicetrade.com/api/job/123',
        'name' => 'HVAC Maintenance'
      },
      'asset' => {
        'id' => 789,
        'name' => 'Main HVAC Unit'
      }
    })

    assert_equal 456, service_request.id
    assert_equal 'https://api.servicetrade.com/api/servicerequest/456', service_request.uri
    assert_equal 'Fix broken HVAC unit', service_request.description
    assert_equal 'open', service_request.status
    assert_equal 'pending', service_request.completion_status
    assert_equal 250.00, service_request.estimated_price
    assert_equal 120, service_request.duration
    assert_equal 1609459200, service_request.window_start
    assert_equal 1609466400, service_request.window_end
    assert_equal 1609459000, service_request.created
    assert_equal 1609459100, service_request.updated
    assert_equal({'id' => 123, 'uri' => 'https://api.servicetrade.com/api/job/123', 'name' => 'HVAC Maintenance'}, service_request.job)
    assert_equal({'id' => 789, 'name' => 'Main HVAC Unit'}, service_request.asset)
  end

  def test_find_service_request
    stub_request(:get, "https://api.servicetrade.com/api/servicerequest/456")
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .to_return(
        status: 200,
        body: '{"data": {"id": 456, "description": "Fix broken HVAC unit", "status": "open"}}',
        headers: {'Content-Type' => 'application/json'}
      )

    service_request = ServiceTrade::ServiceRequest.find(456)
    assert_equal 456, service_request.id
    assert_equal "Fix broken HVAC unit", service_request.description
    assert_equal "open", service_request.status
  end

  def test_create_service_request
    stub_request(:post, "https://api.servicetrade.com/api/servicerequest")
      .with(
        body: '{"description":"Emergency repair","status":"open","estimatedPrice":500}',
        headers: {
          'Cookie' => 'PHPSESSID=test_session_123',
          'Content-Type' => 'application/json'
        }
      )
      .to_return(
        status: 200,
        body: '{"data": {"id": 789, "description": "Emergency repair", "status": "open", "estimatedPrice": 500}}',
        headers: {'Content-Type' => 'application/json'}
      )

    service_request = ServiceTrade::ServiceRequest.create({
      description: "Emergency repair",
      status: "open",
      estimatedPrice: 500
    })

    assert_equal 789, service_request.id
    assert_equal "Emergency repair", service_request.description
    assert_equal "open", service_request.status
    assert_equal 500, service_request.estimated_price
  end

  def test_update_service_request
    stub_request(:put, "https://api.servicetrade.com/api/servicerequest/456")
      .with(
        body: '{"status":"in_progress","estimatedPrice":300}',
        headers: {
          'Cookie' => 'PHPSESSID=test_session_123',
          'Content-Type' => 'application/json'
        }
      )
      .to_return(
        status: 200,
        body: '{"data": {"id": 456, "description": "Fix broken HVAC unit", "status": "in_progress", "estimatedPrice": 300}}',
        headers: {'Content-Type' => 'application/json'}
      )

    service_request = ServiceTrade::ServiceRequest.update(456, {
      status: "in_progress",
      estimatedPrice: 300
    })

    assert_equal 456, service_request.id
    assert_equal "in_progress", service_request.status
    assert_equal 300, service_request.estimated_price
  end

  def test_delete_service_request
    stub_request(:delete, "https://api.servicetrade.com/api/servicerequest/456")
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .to_return(
        status: 200,
        body: '{}',
        headers: {'Content-Type' => 'application/json'}
      )

    result = ServiceTrade::ServiceRequest.delete(456)
    assert_equal true, result
  end

  def test_list_service_requests_by_job
    stub_request(:get, "https://api.servicetrade.com/api/servicerequest")
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .to_return(
        status: 200,
        body: '{"data": {"serviceRequests": [{"id": 456, "description": "Fix HVAC", "status": "open"}]}}',
        headers: {'Content-Type' => 'application/json'}
      )

    service_requests = ServiceTrade::ServiceRequest.by_job(123)
    assert_kind_of ServiceTrade::ListResponse, service_requests
  end

  def test_list_service_requests_by_location
    stub_request(:get, "https://api.servicetrade.com/api/servicerequest")
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .to_return(
        status: 200,
        body: '{"data": {"serviceRequests": [{"id": 456, "description": "Fix HVAC", "status": "open"}]}}',
        headers: {'Content-Type' => 'application/json'}
      )

    service_requests = ServiceTrade::ServiceRequest.by_location(789)
    assert_kind_of ServiceTrade::ListResponse, service_requests
  end

  def test_list_service_requests_by_status
    stub_request(:get, "https://api.servicetrade.com/api/servicerequest")
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .to_return(
        status: 200,
        body: '{"data": {"serviceRequests": [{"id": 456, "description": "Fix HVAC", "status": "open"}]}}',
        headers: {'Content-Type' => 'application/json'}
      )

    service_requests = ServiceTrade::ServiceRequest.by_status("open")
    assert_kind_of ServiceTrade::ListResponse, service_requests
  end

  def test_list_service_requests_by_appointment
    stub_request(:get, "https://api.servicetrade.com/api/servicerequest")
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .to_return(
        status: 200,
        body: '{"data": {"serviceRequests": [{"id": 456, "description": "Fix HVAC", "status": "open"}]}}',
        headers: {'Content-Type' => 'application/json'}
      )

    service_requests = ServiceTrade::ServiceRequest.by_appointment(321)
    assert_kind_of ServiceTrade::ListResponse, service_requests
  end

  def test_list_service_requests_by_service_line_array
    stub_request(:get, "https://api.servicetrade.com/api/servicerequest")
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .to_return(
        status: 200,
        body: '{"data": {"serviceRequests": [{"id": 456, "description": "Fix HVAC", "status": "open"}]}}',
        headers: {'Content-Type' => 'application/json'}
      )

    service_requests = ServiceTrade::ServiceRequest.by_service_line([1, 2, 3])
    assert_kind_of ServiceTrade::ListResponse, service_requests
  end

  def test_list_service_requests_by_asset
    stub_request(:get, "https://api.servicetrade.com/api/servicerequest")
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .to_return(
        status: 200,
        body: '{"data": {"serviceRequests": [{"id": 456, "description": "Fix HVAC", "status": "open"}]}}',
        headers: {'Content-Type' => 'application/json'}
      )

    service_requests = ServiceTrade::ServiceRequest.by_asset(987)
    assert_kind_of ServiceTrade::ListResponse, service_requests
  end

  def test_convenience_status_methods
    stub_request(:get, "https://api.servicetrade.com/api/servicerequest")
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .to_return(
        status: 200,
        body: '{"data": {"serviceRequests": []}}',
        headers: {'Content-Type' => 'application/json'}
      )

    assert_kind_of ServiceTrade::ListResponse, ServiceTrade::ServiceRequest.open_requests

    # Test other status methods would work similarly
    %w[in_progress_requests closed_requests canceled_requests void_requests].each do |method|
      assert_respond_to ServiceTrade::ServiceRequest, method
    end
  end

  def test_status_check_methods
    open_request = ServiceTrade::ServiceRequest.new({'status' => 'open'})
    in_progress_request = ServiceTrade::ServiceRequest.new({'status' => 'in_progress'})
    closed_request = ServiceTrade::ServiceRequest.new({'status' => 'closed'})
    canceled_request = ServiceTrade::ServiceRequest.new({'status' => 'canceled'})
    void_request = ServiceTrade::ServiceRequest.new({'status' => 'void'})

    assert open_request.open?
    assert_false open_request.in_progress?
    assert_false open_request.closed?
    assert_false open_request.canceled?
    assert_false open_request.void?

    assert in_progress_request.in_progress?
    assert_false in_progress_request.open?

    assert closed_request.closed?
    assert_false closed_request.open?

    assert canceled_request.canceled?
    assert_false canceled_request.open?

    assert void_request.void?
    assert_false void_request.open?
  end

  def test_estimated_price_method
    with_price = ServiceTrade::ServiceRequest.new({'estimatedPrice' => 100.0})
    without_price = ServiceTrade::ServiceRequest.new({'estimatedPrice' => nil})
    zero_price = ServiceTrade::ServiceRequest.new({'estimatedPrice' => 0})

    assert with_price.estimated_price?
    assert_false without_price.estimated_price?
    assert_false zero_price.estimated_price?
  end

  def test_time_window_method
    with_window = ServiceTrade::ServiceRequest.new({
      'windowStart' => 1609459200,
      'windowEnd' => 1609466400
    })
    without_window = ServiceTrade::ServiceRequest.new({
      'windowStart' => nil,
      'windowEnd' => nil
    })
    partial_window = ServiceTrade::ServiceRequest.new({
      'windowStart' => 1609459200,
      'windowEnd' => nil
    })

    assert with_window.time_window?
    assert_false without_window.time_window?
    assert_false partial_window.time_window?
  end

  def test_associated_with_job_method
    with_job = ServiceTrade::ServiceRequest.new({
      'job' => {'id' => 123, 'name' => 'Test Job'}
    })
    without_job = ServiceTrade::ServiceRequest.new({'job' => nil})
    empty_job = ServiceTrade::ServiceRequest.new({'job' => {}})

    assert with_job.associated_with_job?
    assert_false without_job.associated_with_job?
    assert_false empty_job.associated_with_job?
  end

  def test_associated_with_appointment_method
    with_appointment = ServiceTrade::ServiceRequest.new({
      'appointment' => {'id' => 456, 'date' => '2021-01-01'}
    })
    without_appointment = ServiceTrade::ServiceRequest.new({'appointment' => nil})
    empty_appointment = ServiceTrade::ServiceRequest.new({'appointment' => {}})

    assert with_appointment.associated_with_appointment?
    assert_false without_appointment.associated_with_appointment?
    assert_false empty_appointment.associated_with_appointment?
  end

  def test_associated_with_asset_method
    with_asset = ServiceTrade::ServiceRequest.new({
      'asset' => {'id' => 789, 'name' => 'HVAC Unit'}
    })
    without_asset = ServiceTrade::ServiceRequest.new({'asset' => nil})
    empty_asset = ServiceTrade::ServiceRequest.new({'asset' => {}})

    assert with_asset.associated_with_asset?
    assert_false without_asset.associated_with_asset?
    assert_false empty_asset.associated_with_asset?
  end

  def test_update_instance_method
    service_request = ServiceTrade::ServiceRequest.new({'id' => 456})

    stub_request(:put, "https://api.servicetrade.com/api/servicerequest/456")
      .with(
        body: '{"status":"closed"}',
        headers: {
          'Cookie' => 'PHPSESSID=test_session_123',
          'Content-Type' => 'application/json'
        }
      )
      .to_return(
        status: 200,
        body: '{"data": {"id": 456, "status": "closed"}}',
        headers: {'Content-Type' => 'application/json'}
      )

    updated_request = service_request.update({status: "closed"})
    assert_equal "closed", updated_request.status
  end

  def test_delete_instance_method
    service_request = ServiceTrade::ServiceRequest.new({'id' => 456})

    stub_request(:delete, "https://api.servicetrade.com/api/servicerequest/456")
      .with(headers: { 'Cookie' => 'PHPSESSID=test_session_123' })
      .to_return(
        status: 200,
        body: '{}',
        headers: {'Content-Type' => 'application/json'}
      )

    result = service_request.delete
    assert_equal true, result
  end
end