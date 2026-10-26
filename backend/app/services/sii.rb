require "net/http"

# Client for the external SII service (simulated with Pipedream). It only
# accepts the request; the result arrives later through the webhook.
module Sii
  class RequestFailed < StandardError; end

  ENDPOINT = "https://eol9cyu9z953tcx.m.pipedream.net/document-sii"

  class << self
    def request_document(document_id:, callback_url:)
      uri = URI(ENV.fetch("SII_ENDPOINT", ENDPOINT))
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
        http.post(uri.request_uri, { callbackUrl: callback_url, documentId: document_id }.to_json,
          "Content-Type" => "application/json")
      end
      raise RequestFailed, "SII responded #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    end

    # Public URL of this API where the SII posts results.
    # The shared token authenticates the webhook, which has no user session.
    def callback_url
      # RENDER_EXTERNAL_URL is the service's public URL when deployed on Render.
      base = ENV["SII_CALLBACK_URL"].presence || ENV["RENDER_EXTERNAL_URL"].presence ||
        raise(RequestFailed, "SII_CALLBACK_URL is not set")
      token = ENV.fetch("SII_WEBHOOK_TOKEN") { raise RequestFailed, "SII_WEBHOOK_TOKEN is not set" }
      "#{base.chomp("/")}/webhooks/sii?#{{ token: token }.to_query}"
    end
  end
end
