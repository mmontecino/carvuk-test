class Receipt < ApplicationRecord
  belongs_to :user
  # Items are validated in #items_are_valid to report per-item messages.
  has_many :receipt_products, dependent: :destroy, validate: false
  has_many :products, through: :receipt_products

  validates :taxes, :net_value, :total_value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :receipt_products, presence: true
  validate :items_are_valid

  # Builds an unsaved receipt from [{ product_id:, amount: }, ...], pricing it
  # from the current product prices and the configured tax rate.
  def self.build_for(user, items)
    products = Product.where(id: items.map { |item| item[:product_id] }).index_by(&:id)
    receipt = user.receipts.new

    items.each do |item|
      product = products[item[:product_id].to_i]
      receipt.receipt_products.new(product: product, unit_price: product&.price, amount: item[:amount])
    end

    receipt.calculate_totals
    receipt
  end

  # Product prices include tax: the total is what the customer pays, and the
  # net value and taxes are broken out of it (net * (1 + rate) = total).
  def calculate_totals
    self.total_value = receipt_products.sum { |item| item.subtotal || 0 }
    self.net_value = (total_value / (1 + Rails.configuration.x.tax_rate)).round(2)
    self.taxes = total_value - net_value
  end

  private
    def items_are_valid
      receipt_products.each.with_index(1) do |item, position|
        next if item.validate

        item.errors.full_messages.each { |message| errors.add(:base, "Item #{position}: #{message}") }
      end

      product_ids = receipt_products.map(&:product_id)
      errors.add(:base, "A product can only appear once per receipt") if product_ids.uniq.size != product_ids.size
    end
end
