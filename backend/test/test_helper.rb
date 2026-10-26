ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Tests never talk to Clerk: a "test-<clerk_id>" bearer token authenticates that user.
# Any other token goes through the real verification (see test/services/clerk_test.rb).
module FakeClerkTokens
  def verify(token)
    return { "sub" => token.delete_prefix("test-") } if token.to_s.start_with?("test-")

    super
  end
end
Clerk.singleton_class.prepend(FakeClerkTokens)

# The real verification needs a publishable key to derive the issuer.
ENV["CLERK_PUBLISHABLE_KEY"] ||= "pk_test_#{Base64.strict_encode64("clerk.example.com$")}"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Minitest 6 dropped minitest/mock: temporarily replaces a singleton method
    # (private ones included) with a callable and restores it afterwards.
    def stub_method(object, name, implementation)
      original = object.method(name)
      was_private = object.singleton_class.private_method_defined?(name)
      object.define_singleton_method(name, implementation)
      yield
    ensure
      object.define_singleton_method(name, original)
      object.singleton_class.send(:private, name) if was_private
    end

    def auth_headers(user)
      { "Authorization" => "Bearer test-#{user.clerk_id}" }
    end
  end
end
