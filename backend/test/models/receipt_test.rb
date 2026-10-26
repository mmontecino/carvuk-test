require "test_helper"

class ReceiptTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert receipts(:one).valid?
  end

  test "requires a user" do
    assert_not Receipt.new(net_value: 1, taxes: 0, total_value: 1).valid?
  end

  test "rejects negative amounts" do
    %i[taxes net_value total_value].each do |attr|
      receipt = receipts(:one)
      receipt[attr] = -1
      assert_not receipt.valid?, "#{attr} should not accept negatives"
    end
  end

  test "has products through receipt_products" do
    assert_includes receipts(:one).products, products(:one)
  end

  test "breaks net value and taxes out of the tax-inclusive total" do
    huevo = Product.create!(name: "Huevo", price: 300)
    leche = Product.create!(name: "Leche", price: 1200)

    original_rate = Rails.configuration.x.tax_rate
    Rails.configuration.x.tax_rate = BigDecimal("0.15")
    receipt = Receipt.build_for(users(:one), [ { product_id: huevo.id, amount: 3 }, { product_id: leche.id, amount: 1 } ])

    assert_equal BigDecimal("2100"), receipt.total_value
    assert_equal BigDecimal("1826.09"), receipt.net_value
    assert_equal BigDecimal("273.91"), receipt.taxes
  ensure
    Rails.configuration.x.tax_rate = original_rate
  end
end
