require "test_helper"

class SiiDocumentJobTest < ActiveJob::TestCase
  setup do
    ENV["SII_CALLBACK_URL"] = "https://abc.ngrok-free.app/"
    ENV["SII_WEBHOOK_TOKEN"] = "secret"
    @requests = []
    requests = @requests
    @original = Sii.method(:request_document)
    Sii.define_singleton_method(:request_document) { |**args| requests << args }
  end

  teardown do
    Sii.define_singleton_method(:request_document, @original)
    ENV.delete("SII_CALLBACK_URL")
    ENV.delete("SII_WEBHOOK_TOKEN")
  end

  test "requests the document with the receipt id and the webhook url" do
    SiiDocumentJob.perform_now(receipts(:one).id)

    assert_equal [ { document_id: receipts(:one).id, callback_url: "https://abc.ngrok-free.app/webhooks/sii?token=secret" } ], @requests
  end

  test "skips receipts that already have a result" do
    receipts(:one).update!(sii_status: "issued")

    SiiDocumentJob.perform_now(receipts(:one).id)

    assert_empty @requests
  end

  test "creating a receipt enqueues the job" do
    receipt = Receipt.build_for(users(:one), [ { product_id: products(:one).id, amount: 1 } ])

    assert_enqueued_with(job: SiiDocumentJob) { receipt.save! }
  end

  test "a missing callback url fails the request" do
    ENV.delete("SII_CALLBACK_URL")

    assert_raises(Sii::RequestFailed) { Sii.callback_url }
  end

  test "falls back to the Render public url" do
    ENV.delete("SII_CALLBACK_URL")
    ENV["RENDER_EXTERNAL_URL"] = "https://api.onrender.com"

    assert_equal "https://api.onrender.com/webhooks/sii?token=secret", Sii.callback_url
  ensure
    ENV.delete("RENDER_EXTERNAL_URL")
  end
end
