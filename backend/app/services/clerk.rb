require "net/http"

# Verifies Clerk session tokens (RS256 JWTs signed with the instance JWKS) and
# looks users up through the Clerk Backend API.
module Clerk
  class InvalidToken < StandardError; end

  JWKS_TTL = 1.hour
  API_URL = "https://api.clerk.com/v1"

  class << self
    # Returns the verified claims, or raises InvalidToken.
    def verify(token)
      raise InvalidToken, "missing token" if token.blank?

      claims, = JWT.decode(token, nil, true,
        algorithms: [ "RS256" ],
        jwks: ->(options) { jwks(refresh: options[:invalidate]) },
        iss: issuer, verify_iss: true)

      authorized = claims["azp"].blank? || authorized_parties.include?(claims["azp"])
      raise InvalidToken, "unauthorized party" unless authorized
      raise InvalidToken, "missing subject" if claims["sub"].blank?

      claims
    rescue JWT::DecodeError => e
      raise InvalidToken, e.message
    end

    # Clerk user payload from the Backend API.
    def fetch_user(clerk_id)
      response = get("#{API_URL}/users/#{URI.encode_uri_component(clerk_id)}",
        "Authorization" => "Bearer #{ENV.fetch("CLERK_SECRET_KEY")}")
      raise InvalidToken, "clerk user lookup failed (#{response.code})" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end

    private
      # The frontend API host is embedded (base64) in the publishable key.
      def issuer
        encoded = ENV.fetch("CLERK_PUBLISHABLE_KEY").split("_", 3).last
        "https://#{Base64.decode64(encoded).delete_suffix("$")}"
      end

      def authorized_parties
        ENV.fetch("FRONTEND_ORIGIN", "http://localhost:5173").split(",")
      end

      def jwks(refresh: false)
        @jwks = nil if refresh || (@jwks_fetched_at && @jwks_fetched_at < JWKS_TTL.ago)
        @jwks ||= begin
          response = get("#{issuer}/.well-known/jwks.json")
          raise InvalidToken, "could not load JWKS" unless response.is_a?(Net::HTTPSuccess)

          @jwks_fetched_at = Time.current
          JSON.parse(response.body).deep_symbolize_keys
        end
      end

      def get(url, headers = {})
        uri = URI(url)
        Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
          http.get(uri.request_uri, headers)
        end
      end
  end
end
