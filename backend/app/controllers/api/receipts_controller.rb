class Api::ReceiptsController < ApplicationController
  before_action :authenticate_user!

  def index
    receipts = current_user.receipts.includes(receipt_products: :product).order(created_at: :desc)
    render json: receipts.map { |receipt| receipt_json(receipt) }
  end

  def show
    receipt = current_user.receipts.includes(receipt_products: :product).find(params[:id])
    render json: receipt_json(receipt)
  end

  def create
    receipt = Receipt.build_for(current_user, items_params)

    if receipt.save
      render json: receipt_json(receipt), status: :created
    else
      render json: { errors: receipt.errors.full_messages }, status: :unprocessable_content
    end
  end

  private
    def items_params
      params.expect(receipt: [ items: [ [ :product_id, :amount ] ] ]).fetch(:items, [])
    end

    def receipt_json(receipt)
      receipt.as_json(only: %i[id net_value taxes total_value created_at sii_status sii_code pdf_url]).merge(
        "items" => receipt.receipt_products.map do |item|
          {
            product_id: item.product_id,
            name: item.product.name,
            unit_price: item.unit_price,
            amount: item.amount,
            subtotal: item.subtotal
          }
        end
      )
    end
end
