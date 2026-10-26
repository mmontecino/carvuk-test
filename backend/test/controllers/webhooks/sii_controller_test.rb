require "test_helper"

class Webhooks::SiiControllerTest < ActionDispatch::IntegrationTest
  setup do
    ENV["SII_WEBHOOK_TOKEN"] = "secret"
    @receipt = receipts(:one)
    @payload = { documentId: @receipt.id, status: "issued", siiCode: "SII-123456", pdfUrl: "https://example.com/doc.pdf" }
  end

  teardown { ENV.delete("SII_WEBHOOK_TOKEN") }

  test "stores the SII result on the receipt" do
    post "/webhooks/sii", params: @payload.merge(token: "secret"), as: :json

    assert_response :no_content
    @receipt.reload
    assert_equal "issued", @receipt.sii_status
    assert_equal "SII-123456", @receipt.sii_code
    assert_equal "https://example.com/doc.pdf", @receipt.pdf_url
  end

  test "handles the same result being delivered twice" do
    2.times do
      post "/webhooks/sii?token=secret", params: @payload, as: :json
      assert_response :no_content
    end

    @receipt.reload
    assert_equal [ "issued", "SII-123456", "https://example.com/doc.pdf" ], [ @receipt.sii_status, @receipt.sii_code, @receipt.pdf_url ]
  end

  test "stores rejected and failed results that carry no code or pdf" do
    %w[rejected failed].each do |status|
      post "/webhooks/sii?token=secret", params: { documentId: @receipt.id, status: status }, as: :json

      assert_response :no_content
      @receipt.reload
      assert_equal status, @receipt.sii_status
      assert_nil @receipt.sii_code
      assert_nil @receipt.pdf_url
    end
  end

  test "keeps the stored code and pdf when a later result does not include them" do
    @receipt.update!(sii_status: "issued", sii_code: "SII-1", pdf_url: "https://example.com/1.pdf")

    post "/webhooks/sii?token=secret", params: { documentId: @receipt.id, status: "issued" }, as: :json

    assert_response :no_content
    @receipt.reload
    assert_equal [ "SII-1", "https://example.com/1.pdf" ], [ @receipt.sii_code, @receipt.pdf_url ]
  end

  test "rejects a missing or wrong token" do
    post "/webhooks/sii", params: @payload, as: :json
    assert_response :unauthorized

    post "/webhooks/sii?token=nope", params: @payload, as: :json
    assert_response :unauthorized
    assert_equal "pending", @receipt.reload.sii_status
  end

  test "rejects every request when no token is configured" do
    ENV.delete("SII_WEBHOOK_TOKEN")

    post "/webhooks/sii?token=", params: @payload, as: :json

    assert_response :unauthorized
  end

  test "returns not found for an unknown document" do
    post "/webhooks/sii?token=secret", params: @payload.merge(documentId: 0), as: :json

    assert_response :not_found
  end

  test "rejects unknown statuses and non-http pdf links" do
    post "/webhooks/sii?token=secret", params: @payload.merge(status: "weird"), as: :json
    assert_response :unprocessable_content

    post "/webhooks/sii?token=secret", params: @payload.merge(pdfUrl: "javascript:alert(1)"), as: :json
    assert_response :unprocessable_content

    post "/webhooks/sii?token=secret", params: @payload.merge(pdfUrl: "https://example.com/a.pdf\njavascript:alert(1)"), as: :json
    assert_response :unprocessable_content
    assert_equal "pending", @receipt.reload.sii_status
  end

  test "requires the document id and status" do
    post "/webhooks/sii?token=secret", params: { status: "issued" }, as: :json

    assert_response :bad_request
  end
end
