require "test_helper"

class Api::ProductsControllerTest < ActionDispatch::IntegrationTest
  test "lists products without authentication" do
    get "/api/products"

    assert_response :ok
    assert_equal Product.count, response.parsed_body.size
    assert_equal %w[id name price], response.parsed_body.first.keys.sort
  end
end
