class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.decimal :price, precision: 12, scale: 2, null: false

      t.timestamps
    end
    add_check_constraint :products, "price > 0", name: "products_price_positive"
  end
end
