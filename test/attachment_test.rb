# frozen_string_literal: true

require_relative "test_helper"

class AttachmentTest < Test::Unit::TestCase
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

  def test_attachment_resource_url
    assert_equal "attachment", ServiceTrade::Attachment.resource_url
  end

  def test_attachment_attributes_exist
    attachment = ServiceTrade::Attachment.new({
      'id' => 123,
      'name' => 'test_document.pdf',
      'contentType' => 'application/pdf',
      'size' => 1024,
      'category' => 'Job Paperwork',
      'purpose' => 'Invoice'
    })

    assert_equal 123, attachment.id
    assert_equal 'test_document.pdf', attachment.name
    assert_equal 'application/pdf', attachment.content_type
    assert_equal 1024, attachment.size
    assert_equal 'Job Paperwork', attachment.category
    assert_equal 'Invoice', attachment.purpose
  end

  def test_attachment_list_with_mocked_response
    response = {
      'data' => {
        'attachments' => [
          {
            'id' => 123,
            'name' => 'document1.pdf',
            'contentType' => 'application/pdf',
            'size' => 1024
          },
          {
            'id' => 456,
            'name' => 'image1.jpg',
            'contentType' => 'image/jpeg',
            'size' => 2048
          }
        ],
        'total' => 2,
        'page' => 1
      }
    }

    stub_request(:get, /.*api\.servicetrade\.com\/api\/attachment.*/)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    attachments_response = ServiceTrade::Attachment.list

    assert_equal 2, attachments_response.data.length
    assert_equal 123, attachments_response.data.first.id
    assert_equal 'document1.pdf', attachments_response.data.first.name
    assert_equal 456, attachments_response.data.last.id
    assert_equal 'image1.jpg', attachments_response.data.last.name
  end

  def test_attachment_find_with_mocked_response
    response = {
      'data' => {
        'id' => 123,
        'name' => 'test_document.pdf',
        'contentType' => 'application/pdf',
        'size' => 1024,
        'description' => 'Test attachment'
      }
    }

    stub_request(:get, "https://api.servicetrade.com/api/attachment/123")
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    attachment = ServiceTrade::Attachment.find(123)

    assert_equal 123, attachment.id
    assert_equal 'test_document.pdf', attachment.name
    assert_equal 'application/pdf', attachment.content_type
    assert_equal 1024, attachment.size
    assert_equal 'Test attachment', attachment.description
  end

  def test_attachment_for_job_with_mocked_response
    response = {
      'data' => {
        'attachments' => [
          {
            'id' => 111,
            'name' => 'job_photo.jpg',
            'contentType' => 'image/jpeg',
            'size' => 3072
          },
          {
            'id' => 222,
            'name' => 'invoice.pdf',
            'contentType' => 'application/pdf',
            'size' => 2048
          }
        ],
        'total' => 2,
        'page' => 1
      }
    }

    stub_request(:get, "https://api.servicetrade.com/api/job/123/attachment?page=1&per_page=100")
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    attachments_response = ServiceTrade::Attachment.for_job(123)

    assert_equal 2, attachments_response.data.length
    assert_equal 111, attachments_response.data.first.id
    assert_equal 'job_photo.jpg', attachments_response.data.first.name
    assert_equal 222, attachments_response.data.last.id
    assert_equal 'invoice.pdf', attachments_response.data.last.name
  end

  def test_job_attachments_instance_method
    job = ServiceTrade::Job.new({'id' => 123, 'name' => 'Test Job'})

    response = {
      'data' => {
        'attachments' => [
          {
            'id' => 999,
            'name' => 'job_attachment.pdf',
            'contentType' => 'application/pdf',
            'size' => 4096
          }
        ],
        'total' => 1,
        'page' => 1
      }
    }

    stub_request(:get, "https://api.servicetrade.com/api/job/123/attachment?page=1&per_page=100")
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    attachments_response = job.attachments

    assert_equal 1, attachments_response.data.length
    assert_equal 999, attachments_response.data.first.id
    assert_equal 'job_attachment.pdf', attachments_response.data.first.name
  end

  def test_job_attachments_with_pagination
    job = ServiceTrade::Job.new({'id' => 456, 'name' => 'Test Job'})

    response = {
      'data' => {
        'attachments' => [
          {
            'id' => 1,
            'name' => 'attachment1.pdf',
            'contentType' => 'application/pdf',
            'size' => 1000
          }
        ],
        'total' => 1,
        'page' => 2,
        'per_page' => 50
      }
    }

    stub_request(:get, "https://api.servicetrade.com/api/job/456/attachment?page=2&per_page=50")
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    attachments_response = job.attachments(page: 2, per_page: 50)

    assert_equal 1, attachments_response.data.length
    assert_equal 2, attachments_response.page
    assert_equal 50, attachments_response.per_page
  end
end
