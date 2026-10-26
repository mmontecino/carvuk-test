class AddUnitPriceToReceiptProducts < ActiveRecord::Migration[8.1]
  def up
    add_column :receipt_products, :unit_price, :decimal, precision: 12, scale: 2

    # Existing items get the product's current price, the best value available.
    execute <<~SQL
      UPDATE receipt_products
      SET unit_price = products.price
      FROM products
      WHERE products.id = receipt_products.product_id
    SQL

    change_column_null :receipt_products, :unit_price, false
    add_check_constraint :receipt_products, "unit_price > 0", name: "receipt_products_unit_price_positive"
  end

  def down
    remove_check_constraint :receipt_products, name: "receipt_products_unit_price_positive"
    remove_column :receipt_products, :unit_price
  end
end
