require "test_helper"

class SiiTest < ActiveSupport::TestCase
  # Records what Sii.request_document sends instead of opening a connection.
  class FakeHttp
    attr_reader :requests

    def initialize(response)
      @response = response
      @requests = []
    end

    def post(path, body, headers)
      @requests << { path: path, body: JSON.parse(body), headers: headers }
      @response
    end
  end

  setup do
    @original_env = ENV.to_h.slice("SII_ENDPOINT", "SII_CALLBACK_URL", "SII_WEBHOOK_TOKEN")
    ENV.delete("SII_ENDPOINT")
  end

  teardown do
    %w[SII_ENDPOINT SII_CALLBACK_URL SII_WEBHOOK_TOKEN].each { |name| ENV[name] = @original_env[name] }
  end

  test "posts the document id and the callback url as JSON to the SII" do
    http, connections = request_document(Net::HTTPOK.new("1.1", "200", "OK"))

    assert_equal 1, http.requests.size
    request = http.requests.first
    assert_equal "/document-sii", request[:path]
    assert_equal({ "callbackUrl" => "https://api.example.com/webhooks/sii?token=t", "documentId" => 42 }, request[:body])
    assert_equal "application/json", request[:headers]["Content-Type"]
    assert_equal [ "eol9cyu9z953tcx.m.pipedream.net", 443, true ], connections.first.values_at(:host, :port, :use_ssl)
  end

  test "uses SII_ENDPOINT when it is set" do
    ENV["SII_ENDPOINT"] = "http://sii.test:8080/documents"

    http, connections = request_document(Net::HTTPOK.new("1.1", "200", "OK"))

    assert_equal "/documents", http.requests.first[:path]
    assert_equal [ "sii.test", 8080, false ], connections.first.values_at(:host, :port, :use_ssl)
  end

  test "accepts any successful response" do
    assert_nothing_raised { request_document(Net::HTTPAccepted.new("1.1", "202", "Accepted")) }
  end

  test "raises when the SII does not accept the request" do
    [ Net::HTTPInternalServerError.new("1.1", "500", "error"), Net::HTTPNotFound.new("1.1", "404", "missing") ].each do |response|
      error = assert_raises(Sii::RequestFailed) { request_document(response) }
      assert_equal "SII responded #{response.code}", error.message
    end
  end

  test "builds the callback url with the webhook token" do
    ENV["SII_CALLBACK_URL"] = "https://api.example.com/"
    ENV["SII_WEBHOOK_TOKEN"] = "a b&c"

    assert_equal "https://api.example.com/webhooks/sii?token=a+b%26c", Sii.callback_url
  end

  test "requires a webhook token to build the callback url" do
    ENV["SII_CALLBACK_URL"] = "https://api.example.com"
    ENV.delete("SII_WEBHOOK_TOKEN")

    assert_raises(Sii::RequestFailed) { Sii.callback_url }
  end

  private
    # Runs Sii.request_document against a fake connection; returns it and the connection options.
    def request_document(response)
      http = FakeHttp.new(response)
      connections = []
      connect = lambda do |host, port, **options, &block|
        connections << { host: host, port: port, **options }
        block.call(http)
      end

      stub_method(Net::HTTP, :start, connect) do
        Sii.request_document(document_id: 42, callback_url: "https://api.example.com/webhooks/sii?token=t")
      end
      [ http, connections ]
    end
end
