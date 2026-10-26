class ReplaceDeviseWithClerk < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :clerk_id, :string
    add_index :users, :clerk_id, unique: true

    remove_column :users, :encrypted_password, :string, default: "", null: false
    remove_column :users, :reset_password_token, :string
    remove_column :users, :reset_password_sent_at, :datetime
    remove_column :users, :remember_created_at, :datetime

    drop_table :jwt_denylists do |t|
      t.string :jti, null: false
      t.datetime :exp, null: false
      t.index :jti
    end
  end
end
