class Product < ApplicationRecord
  has_many :receipt_products, dependent: :restrict_with_error
  has_many :receipts, through: :receipt_products

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
end
