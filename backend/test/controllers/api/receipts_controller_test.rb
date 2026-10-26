require "test_helper"

class Api::ReceiptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @headers = auth_headers(@user)
  end

  test "requires authentication" do
    get "/api/receipts"
    assert_response :unauthorized

    post "/api/receipts", params: { receipt: { items: [ { product_id: products(:one).id, amount: 1 } ] } }, as: :json
    assert_response :unauthorized
  end

  test "lists only the current user's receipts" do
    get "/api/receipts", headers: @headers

    assert_response :ok
    assert_equal [ receipts(:one).id ], response.parsed_body.map { |r| r["id"] }
  end

  test "shows a receipt with its items" do
    get "/api/receipts/#{receipts(:one).id}", headers: @headers

    assert_response :ok
    item = response.parsed_body["items"].first
    assert_equal products(:one).id, item["product_id"]
    assert_equal 1, item["amount"]
  end

  test "does not show another user's receipt" do
    get "/api/receipts/#{receipts(:two).id}", headers: @headers

    assert_response :not_found
  end

  test "creates a receipt and calculates totals with the tax rate" do
    items = [ { product_id: products(:one).id, amount: 2 }, { product_id: products(:two).id, amount: 1 } ]

    assert_difference -> { @user.receipts.count } => 1, -> { ReceiptProduct.count } => 2 do
      post "/api/receipts", params: { receipt: { items: items } }, headers: @headers, as: :json
    end

    assert_response :created
    body = response.parsed_body
    total = products(:one).price * 2 + products(:two).price
    net = (total / (1 + Rails.configuration.x.tax_rate)).round(2)
    assert_equal total, BigDecimal(body["total_value"])
    assert_equal net, BigDecimal(body["net_value"])
    assert_equal total - net, BigDecimal(body["taxes"])
    assert_equal products(:one).price, BigDecimal(body["items"].find { |i| i["product_id"] == products(:one).id }["unit_price"])
  end

  test "keeps the price paid when the product price changes later" do
    post "/api/receipts", params: { receipt: { items: [ { product_id: products(:one).id, amount: 1 } ] } }, headers: @headers, as: :json
    id = response.parsed_body["id"]
    paid = products(:one).price

    products(:one).update!(price: paid * 2)
    get "/api/receipts/#{id}", headers: @headers

    item = response.parsed_body["items"].first
    assert_equal paid, BigDecimal(item["unit_price"])
    assert_equal paid, BigDecimal(item["subtotal"])
  end

  test "rejects a receipt without items" do
    post "/api/receipts", params: { receipt: { items: [] } }, headers: @headers, as: :json

    assert_response :unprocessable_content
  end

  test "rejects unknown products, invalid amounts and repeated products" do
    [
      [ { product_id: 0, amount: 1 } ],
      [ { product_id: products(:one).id, amount: 0 } ],
      [ { product_id: products(:one).id, amount: 1 }, { product_id: products(:one).id, amount: 2 } ]
    ].each do |items|
      assert_no_difference "Receipt.count" do
        post "/api/receipts", params: { receipt: { items: items } }, headers: @headers, as: :json
      end
      assert_response :unprocessable_content
      assert_not_empty response.parsed_body["errors"]
    end
  end
end
