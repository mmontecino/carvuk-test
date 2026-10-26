class ReceiptProduct < ApplicationRecord
  belongs_to :receipt
  belongs_to :product

  # Freeze the product's price at the moment the item is added to the receipt.
  before_validation :set_unit_price, on: :create

  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
  validates :product_id, uniqueness: { scope: :receipt_id }

  def subtotal
    unit_price * amount if unit_price && amount.to_i.positive?
  end

  private
    def set_unit_price
      self.unit_price ||= product&.price
    end
end
