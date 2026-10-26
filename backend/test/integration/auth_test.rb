require "test_helper"

class AuthTest < ActionDispatch::IntegrationTest
  test "sign up returns the user and a token" do
    post "/api/users", params: { user: { name: "Carla", email: "carla@example.com", password: "password123" } }, as: :json

    assert_response :created
    assert_equal "Carla", response.parsed_body.dig("user", "name")
    assert_match(/\ABearer /, response.headers["Authorization"])
  end

  test "sign up with invalid data returns errors" do
    post "/api/users", params: { user: { name: "", email: "bad", password: "1" } }, as: :json

    assert_response :unprocessable_content
    assert_not_empty response.parsed_body["errors"]
  end

  test "sign in returns a token and sign out revokes it" do
    post "/api/users/sign_in", params: { user: { email: users(:one).email, password: "password123" } }, as: :json
    assert_response :ok
    token = response.headers["Authorization"]
    assert_match(/\ABearer /, token)

    delete "/api/users/sign_out", headers: { "Authorization" => token }
    assert_response :no_content

    get "/api/receipts", headers: { "Authorization" => token }
    assert_response :unauthorized
  end

  test "sign in with a wrong password is rejected" do
    post "/api/users/sign_in", params: { user: { email: users(:one).email, password: "nope" } }, as: :json

    assert_response :unauthorized
  end
end
