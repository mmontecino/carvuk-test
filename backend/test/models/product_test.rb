require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "valid with name and positive price" do
    assert Product.new(name: "Bujía", price: 1).valid?
  end

  test "requires a name" do
    assert_not Product.new(name: "", price: 1).valid?
  end

  test "requires a price greater than zero" do
    assert_not Product.new(name: "Bujía").valid?
    assert_not Product.new(name: "Bujía", price: 0).valid?
    assert_not Product.new(name: "Bujía", price: -5).valid?
  end

  test "cannot be destroyed while used in a receipt" do
    assert_not products(:one).destroy
  end
end
