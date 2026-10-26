# Asks the SII to issue the document for a receipt. The outcome is recorded
# by Webhooks::SiiController when the SII calls back.
class SiiDocumentJob < ApplicationJob
  queue_as :default

  retry_on Sii::RequestFailed, SocketError, Timeout::Error, SystemCallError, wait: :polynomially_longer, attempts: 5 do |job, _error|
    Receipt.find_by(id: job.arguments.first)&.update!(sii_status: "failed")
  end
  discard_on ActiveJob::DeserializationError

  def perform(receipt_id)
    receipt = Receipt.find(receipt_id)
    return unless receipt.sii_status == "pending"

    # Without a public URL (local development) the SII cannot call back, so the
    # receipt stays pending instead of burning retries.
    unless Sii.public_url_configured?
      logger.warn "SII_CALLBACK_URL is not set; receipt #{receipt.id} stays pending"
      return
    end

    Sii.request_document(document_id: receipt.id, callback_url: Sii.callback_url)
  end
end
