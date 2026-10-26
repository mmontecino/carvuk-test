ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Tests never talk to Clerk: a "test-<clerk_id>" bearer token authenticates that user.
module FakeClerkTokens
  def verify(token)
    return { "sub" => token.delete_prefix("test-") } if token.to_s.start_with?("test-")

    raise Clerk::InvalidToken, "invalid token"
  end
end
Clerk.singleton_class.prepend(FakeClerkTokens)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    def auth_headers(user)
      { "Authorization" => "Bearer test-#{user.clerk_id}" }
    end
  end
end
