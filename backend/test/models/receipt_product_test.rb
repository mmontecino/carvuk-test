require "test_helper"

class ReceiptProductTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert receipt_products(:one).valid?
  end

  test "requires an integer amount greater than zero" do
    [ nil, 0, -1, 1.5 ].each do |amount|
      assert_not ReceiptProduct.new(receipt: receipts(:one), product: products(:two), amount: amount).valid?
    end
  end

  test "does not repeat a product in the same receipt" do
    assert_not ReceiptProduct.new(receipt: receipts(:one), product: products(:one), amount: 2).valid?
  end

  test "takes the unit price from the product when not given" do
    item = ReceiptProduct.new(receipt: receipts(:one), product: products(:two), amount: 2)

    assert item.valid?
    assert_equal products(:two).price, item.unit_price
    assert_equal products(:two).price * 2, item.subtotal
  end
end
