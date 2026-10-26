require "test_helper"

class AuthTest < ActionDispatch::IntegrationTest
  test "accepts a valid Clerk token" do
    get "/api/receipts", headers: auth_headers(users(:one))

    assert_response :ok
  end

  test "rejects a missing token" do
    get "/api/receipts"

    assert_response :unauthorized
  end

  test "rejects an invalid token" do
    get "/api/receipts", headers: { "Authorization" => "Bearer garbage" }

    assert_response :unauthorized
  end

  test "rejects a malformed authorization header" do
    get "/api/receipts", headers: { "Authorization" => "Basic abc" }

    assert_response :unauthorized
  end
end
