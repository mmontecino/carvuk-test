# Receives the SII's result for a document. Not tied to a user session: it is
# authenticated with the shared token embedded in the callback URL.
class Webhooks::SiiController < ApplicationController
  def create
    return head :unauthorized unless valid_token?

    receipt = Receipt.find(params.require(:documentId))
    if receipt.update(sii_status: params.require(:status), sii_code: params[:siiCode], pdf_url: params[:pdfUrl])
      head :no_content
    else
      render json: { errors: receipt.errors.full_messages }, status: :unprocessable_content
    end
  end

  private
    def valid_token?
      expected = ENV["SII_WEBHOOK_TOKEN"].to_s
      expected.present? && ActiveSupport::SecurityUtils.secure_compare(params[:token].to_s, expected)
    end
end
