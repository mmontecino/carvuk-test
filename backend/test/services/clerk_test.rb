require "test_helper"

class ClerkTest < ActiveSupport::TestCase
  ISSUER = "https://clerk.example.com"
  KEY = OpenSSL::PKey::RSA.generate(2048)
  OTHER_KEY = OpenSSL::PKey::RSA.generate(2048)

  # A 200 response that Clerk's JWKS request accepts.
  class JwksResponse < Net::HTTPOK
    def initialize(body)
      super("1.1", "200", "OK")
      @body = body
      @read = true
    end
  end

  setup do
    @original_env = ENV.to_h.slice("CLERK_PUBLISHABLE_KEY", "FRONTEND_ORIGIN")
    ENV["CLERK_PUBLISHABLE_KEY"] = "pk_test_#{Base64.strict_encode64("clerk.example.com$")}"
    ENV["FRONTEND_ORIGIN"] = "http://localhost:5173,https://app.example.com"
    reset_jwks_cache
  end

  teardown do
    %w[CLERK_PUBLISHABLE_KEY FRONTEND_ORIGIN].each { |name| ENV[name] = @original_env[name] }
    reset_jwks_cache
  end

  test "returns the claims of a valid token" do
    with_jwks(KEY) do
      claims = Clerk.verify(token)

      assert_equal "user_1", claims["sub"]
    end
  end

  test "rejects an expired token" do
    with_jwks(KEY) { assert_invalid token("exp" => 1.minute.ago.to_i) }
  end

  test "rejects a token signed with a key that is not published" do
    with_jwks(KEY) { assert_invalid token(key: OTHER_KEY) }
  end

  test "rejects a token whose key id is unknown" do
    with_jwks(KEY) { assert_invalid token(key: OTHER_KEY, kid: "unknown") }
  end

  test "rejects a token from another issuer" do
    with_jwks(KEY) { assert_invalid token("iss" => "https://evil.example.com") }
  end

  test "rejects a token without a subject" do
    with_jwks(KEY) { assert_invalid token("sub" => nil) }
  end

  test "rejects blank tokens" do
    assert_invalid nil
    assert_invalid ""
  end

  test "rejects tokens that are not RS256" do
    hmac = JWT.encode(payload, "secret", "HS256", { kid: kid(KEY) })
    unsigned = JWT.encode(payload, nil, "none", { kid: kid(KEY) })

    with_jwks(KEY) do
      assert_invalid hmac
      assert_invalid unsigned
    end
  end

  test "accepts only the configured authorized parties" do
    with_jwks(KEY) do
      assert Clerk.verify(token("azp" => "http://localhost:5173"))
      assert Clerk.verify(token("azp" => "https://app.example.com"))
      assert Clerk.verify(token("azp" => nil))
      assert_invalid token("azp" => "https://evil.example.com")
    end
  end

  test "fetches the JWKS from the issuer once and caches it" do
    with_jwks(KEY) do |urls|
      2.times { Clerk.verify(token) }

      assert_equal [ "#{ISSUER}/.well-known/jwks.json" ], urls
    end
  end

  test "refetches the JWKS when the key id is unknown, e.g. after a key rotation" do
    with_jwks([ KEY ], [ KEY, OTHER_KEY ]) do |urls|
      Clerk.verify(token)

      assert Clerk.verify(token(key: OTHER_KEY))
      assert_equal 2, urls.size
    end
  end

  test "refetches the JWKS after the cache expires" do
    with_jwks(KEY) do |urls|
      Clerk.verify(token("exp" => 1.day.from_now.to_i))
      travel(Clerk::JWKS_TTL + 1.minute)

      Clerk.verify(token("exp" => 1.day.from_now.to_i))

      assert_equal 2, urls.size
    end
  end

  test "rejects the token when the JWKS cannot be loaded" do
    failure = Net::HTTPInternalServerError.new("1.1", "500", "error")

    stub_method(Clerk, :get, ->(_url, _headers = {}) { failure }) do
      assert_invalid token
    end
  end

  private
    def kid(key)
      JWT::JWK.new(key).kid
    end

    def payload(overrides = {})
      { "sub" => "user_1", "iss" => ISSUER, "azp" => "http://localhost:5173",
        "iat" => Time.now.to_i, "exp" => 1.hour.from_now.to_i }.merge(overrides).compact
    end

    # Overrides are claims; key and kid choose how the token is signed.
    def token(overrides = {})
      key = overrides.delete(:key) || KEY
      key_id = overrides.delete(:kid) || kid(key)
      JWT.encode(payload(overrides), key, "RS256", { kid: key_id })
    end

    def assert_invalid(token)
      assert_raises(Clerk::InvalidToken) { Clerk.verify(token) }
    end

    # Serves the given key sets as the JWKS (one per fetch, the last repeating)
    # and yields the URLs requested.
    def with_jwks(*key_sets)
      key_sets = [ key_sets.flatten ] unless key_sets.first.is_a?(Array)
      urls = []
      serve = lambda do |url, _headers = {}|
        urls << url
        keys = key_sets[[ urls.size, key_sets.size ].min - 1]
        JwksResponse.new({ keys: keys.map { |key| JWT::JWK.new(key).export } }.to_json)
      end

      stub_method(Clerk, :get, serve) { yield urls }
    end

    def reset_jwks_cache
      Clerk.instance_variable_set(:@jwks, nil)
      Clerk.instance_variable_set(:@jwks_fetched_at, nil)
    end
end
