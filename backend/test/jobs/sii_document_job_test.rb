require "test_helper"

class SiiDocumentJobTest < ActiveJob::TestCase
  setup do
    ENV["SII_CALLBACK_URL"] = "https://api.example.com/"
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

    assert_equal [ { document_id: receipts(:one).id, callback_url: "https://api.example.com/webhooks/sii?token=secret" } ], @requests
  end

  test "leaves the receipt pending when there is no public url" do
    ENV.delete("SII_CALLBACK_URL")
    ENV.delete("RENDER_EXTERNAL_URL")

    assert_no_enqueued_jobs only: SiiDocumentJob do
      SiiDocumentJob.perform_now(receipts(:one).id)
    end

    assert_empty @requests
    assert_equal "pending", receipts(:one).reload.sii_status
  end

  test "skips receipts that already have a result" do
    receipts(:one).update!(sii_status: "issued")

    SiiDocumentJob.perform_now(receipts(:one).id)

    assert_empty @requests
  end

  test "retries later when the SII request fails" do
    [ Sii::RequestFailed, Timeout::Error, SocketError, Errno::ECONNREFUSED ].each do |error|
      Sii.define_singleton_method(:request_document) { |**| raise error }

      assert_enqueued_jobs 1, only: SiiDocumentJob do
        assert_nothing_raised { SiiDocumentJob.perform_now(receipts(:one).id) }
      end
      assert_equal "pending", receipts(:one).reload.sii_status
      clear_enqueued_jobs
    end
  end

  test "marks the receipt as failed once the retries run out" do
    Sii.define_singleton_method(:request_document) { |**| raise Sii::RequestFailed, "boom" }
    job = SiiDocumentJob.new(receipts(:one).id)

    4.times { job.perform_now }
    assert_equal "pending", receipts(:one).reload.sii_status

    assert_no_enqueued_jobs only: SiiDocumentJob do
      job.perform_now
    end
    assert_equal "failed", receipts(:one).reload.sii_status
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
