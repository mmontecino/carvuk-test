require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(**attrs)
    User.new({ name: "Carla", email: "carla@example.com" }.merge(attrs))
  end

  def clerk_payload(id:, email:, first_name: "Carla", last_name: "Diaz")
    { "id" => id, "first_name" => first_name, "last_name" => last_name,
      "primary_email_address_id" => "idn_1",
      "email_addresses" => [ { "id" => "idn_1", "email_address" => email } ] }
  end

  # Minitest 6 dropped minitest/mock, so swap Clerk.fetch_user by hand.
  def with_clerk_user(payload)
    original = Clerk.method(:fetch_user)
    Clerk.define_singleton_method(:fetch_user) { |_id| payload }
    yield
  ensure
    Clerk.define_singleton_method(:fetch_user, original)
  end

  test "valid with name and email" do
    assert build_user.valid?
  end

  test "requires a name" do
    assert_not build_user(name: "").valid?
  end

  test "requires a unique, well-formed email" do
    assert_not build_user(email: "").valid?
    assert_not build_user(email: "not-an-email").valid?
    assert_not build_user(email: users(:one).email).valid?
  end

  test "destroys its receipts" do
    assert_difference("Receipt.count", -1) { users(:one).destroy }
  end

  test "from_clerk returns the already linked user without calling Clerk" do
    assert_equal users(:one), User.from_clerk("user_ana")
  end

  test "from_clerk links an existing user by email" do
    legacy = User.create!(name: "Legacy", email: "legacy@example.com")

    with_clerk_user(clerk_payload(id: "user_legacy", email: "Legacy@example.com")) do
      assert_no_difference("User.count") { assert_equal legacy, User.from_clerk("user_legacy") }
    end
    assert_equal "user_legacy", legacy.reload.clerk_id
  end

  test "from_clerk creates a user the first time it is seen" do
    with_clerk_user(clerk_payload(id: "user_new", email: "new@example.com")) do
      user = assert_difference("User.count", 1) { User.from_clerk("user_new") }
      assert_equal "Carla Diaz", user.name
      assert_equal "new@example.com", user.email
    end
  end
end
