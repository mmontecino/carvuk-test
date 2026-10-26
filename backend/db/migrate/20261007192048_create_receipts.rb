class CreateReceipts < ActiveRecord::Migration[8.1]
  def change
    create_table :receipts do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :taxes, precision: 12, scale: 2, null: false, default: 0
      t.decimal :net_value, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total_value, precision: 12, scale: 2, null: false, default: 0

      t.timestamps
    end
    add_check_constraint :receipts, "taxes >= 0", name: "receipts_taxes_non_negative"
    add_check_constraint :receipts, "net_value >= 0", name: "receipts_net_value_non_negative"
    add_check_constraint :receipts, "total_value >= 0", name: "receipts_total_value_non_negative"
  end
end
