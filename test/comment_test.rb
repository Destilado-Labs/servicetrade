# frozen_string_literal: true

require_relative "test_helper"

class CommentTest < Test::Unit::TestCase
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

  def test_comment_resource_url
    assert_equal "comment", ServiceTrade::Comment.resource_url
  end

  def test_comment_attributes_exist
    comment = ServiceTrade::Comment.new({
      'id' => 123,
      'comment' => 'This is a test comment',
      'visibility' => 'private',
      'created' => '2024-01-01T12:00:00Z',
      'updated' => '2024-01-01T12:00:00Z',
      'createdBy' => {
        'id' => 456,
        'name' => 'Test User'
      },
      'job' => {
        'id' => 789,
        'name' => 'Test Job'
      }
    })

    assert_equal 123, comment.id
    assert_equal 'This is a test comment', comment.comment
    assert_equal 'private', comment.visibility
    assert_equal '2024-01-01T12:00:00Z', comment.created
    assert_equal '2024-01-01T12:00:00Z', comment.updated
    assert_equal 456, comment.created_by['id']
    assert_equal 789, comment.job['id']
  end

  def test_comment_find_with_mocked_response
    response = {
      'data' => {
        'id' => 123,
        'comment' => 'Test comment',
        'visibility' => 'private',
        'created' => '2024-01-01T12:00:00Z'
      }
    }

    stub_request(:get, "https://api.servicetrade.com/api/comment/123")
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    comment = ServiceTrade::Comment.find(123)

    assert_equal 123, comment.id
    assert_equal 'Test comment', comment.comment
    assert_equal 'private', comment.visibility
  end

  def test_comments_for_job_with_mocked_response
    job_id = 789
    response = {
      'data' => {
        'comments' => [
          {
            'id' => 123,
            'comment' => 'First comment',
            'visibility' => 'private',
            'created' => '2024-01-01T12:00:00Z'
          },
          {
            'id' => 456,
            'comment' => 'Second comment',
            'visibility' => 'tech',
            'created' => '2024-01-02T12:00:00Z'
          }
        ],
        'total' => 2,
        'page' => 1
      }
    }

    stub_request(:get, "https://api.servicetrade.com/api/job/#{job_id}/comment?page=1&per_page=100")
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    comments_response = ServiceTrade::Comment.for_job(job_id)

    assert_equal 2, comments_response.data.length
    assert_equal 123, comments_response.data.first.id
    assert_equal 'First comment', comments_response.data.first.comment
    assert_equal 456, comments_response.data.last.id
    assert_equal 'Second comment', comments_response.data.last.comment
  end

  def test_create_comment_for_job_with_mocked_response
    job_id = 789
    request_params = {
      'comment' => 'New comment on job',
      'createdBy' => 456,
      'visibility' => 'private'
    }

    response = {
      'data' => {
        'id' => 999,
        'comment' => 'New comment on job',
        'visibility' => 'private',
        'created' => '2024-01-03T12:00:00Z',
        'createdBy' => {
          'id' => 456,
          'name' => 'Test User'
        },
        'job' => {
          'id' => 789,
          'name' => 'Test Job'
        }
      }
    }

    stub_request(:post, "https://api.servicetrade.com/api/job/#{job_id}/comment")
      .with(body: request_params.to_json)
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    comment = ServiceTrade::Comment.create_for_job(job_id, request_params)

    assert_equal 999, comment.id
    assert_equal 'New comment on job', comment.comment
    assert_equal 'private', comment.visibility
    assert_equal 456, comment.created_by['id']
    assert_equal 789, comment.job['id']
  end

  def test_comments_for_job_with_pagination
    job_id = 789
    response = {
      'data' => {
        'comments' => [
          {'id' => 1, 'comment' => 'Comment 1'},
          {'id' => 2, 'comment' => 'Comment 2'}
        ],
        'total' => 2,
        'page' => 1,
        'per_page' => 10
      }
    }

    stub_request(:get, "https://api.servicetrade.com/api/job/#{job_id}/comment?page=1&per_page=10")
      .to_return(
        status: 200,
        body: response.to_json,
        headers: {'Content-Type' => 'application/json'}
      )

    comments_response = ServiceTrade::Comment.for_job(job_id, page: 1, per_page: 10)

    assert_equal 2, comments_response.data.length
    assert_equal 1, comments_response.page
    assert_equal 10, comments_response.per_page
    assert_equal 2, comments_response.total_count
  end
end
