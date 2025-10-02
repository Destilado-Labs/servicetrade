# frozen_string_literal: true

require_relative "test_helper"

class ServiceLineTest < Test::Unit::TestCase
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

  def test_service_line_list_with_mocked_response
    response = {
      'data' => {
        'totalPages' => 1,
        'page' => 1,
        'total' => 2,
        'per_page' => 100,
        'servicelines' => [
          {
            'id' => 5,
            'name' => 'Sprinkler',
            'trade' => 'Fire Protection',
            'icon' => 'https://app.servicetrade.com/image/icons/service_lines/32/SP.png',
            'abbr' => 'SP'
          },
          {
            'id' => 10,
            'name' => 'Fire Alarm',
            'trade' => 'Fire Protection',
            'icon' => 'https://app.servicetrade.com/image/icons/service_lines/32/FA.png',
            'abbr' => 'FA'
          }
        ]
      }
    }

    # Generic catch-all stub
    stub_request(:get, /api.servicetrade.com\/api\/serviceline/)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    stub_request(:get, "https://api.servicetrade.com/api/serviceline?page=1&per_page=100")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'Cookie' => 'PHPSESSID=test_session_123'
        }
      )
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    service_lines_response = ServiceTrade::ServiceLine.list

    assert_equal 2, service_lines_response.data.length
    assert_equal 5, service_lines_response.data.first.id
    assert_equal 'Sprinkler', service_lines_response.data.first.name
    assert_equal 'Fire Protection', service_lines_response.data.first.trade
    assert_equal 'SP', service_lines_response.data.first.abbr
    assert_equal 10, service_lines_response.data.last.id
    assert_equal 'Fire Alarm', service_lines_response.data.last.name
  end

  def test_service_line_find_with_mocked_response
    response = {
      'data' => {
        'id' => 5,
        'name' => 'Sprinkler',
        'trade' => 'Fire Protection',
        'icon' => 'https://app.servicetrade.com/image/icons/service_lines/32/SP.png',
        'abbr' => 'SP'
      }
    }

    stub_request(:get, "https://api.servicetrade.com/api/serviceline/5")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'Cookie' => 'PHPSESSID=test_session_123'
        }
      )
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    service_line = ServiceTrade::ServiceLine.find(5)

    assert_equal 5, service_line.id
    assert_equal 'Sprinkler', service_line.name
    assert_equal 'Fire Protection', service_line.trade
    assert_equal 'SP', service_line.abbr
    assert_equal 'https://app.servicetrade.com/image/icons/service_lines/32/SP.png', service_line.icon
  end
end
