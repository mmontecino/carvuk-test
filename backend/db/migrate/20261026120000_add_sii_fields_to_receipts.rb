class AddSiiFieldsToReceipts < ActiveRecord::Migration[8.1]
  def change
    add_column :receipts, :sii_status, :string, null: false, default: "pending"
    add_column :receipts, :sii_code, :string
    add_column :receipts, :pdf_url, :string
  end
end
