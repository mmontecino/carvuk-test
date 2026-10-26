class CreateReceiptProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :receipt_products do |t|
      t.references :receipt, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :amount, null: false

      t.timestamps
    end
    add_index :receipt_products, [ :receipt_id, :product_id ], unique: true
    add_check_constraint :receipt_products, "amount > 0", name: "receipt_products_amount_positive"
  end
end
