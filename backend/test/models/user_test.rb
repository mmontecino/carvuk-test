require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(**attrs)
    User.new({ name: "Carla", email: "carla@example.com", password: "password123" }.merge(attrs))
  end

  test "valid with name, email and password" do
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

  test "encrypts the password" do
    user = build_user
    user.save!
    assert_not_equal "password123", user.encrypted_password
    assert user.valid_password?("password123")
  end

  test "destroys its receipts" do
    assert_difference("Receipt.count", -1) { users(:one).destroy }
  end
end
