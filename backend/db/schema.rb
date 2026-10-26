# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_26_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "price", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "price > 0::numeric", name: "products_price_positive"
  end

  create_table "receipt_products", force: :cascade do |t|
    t.bigint "receipt_id", null: false
    t.bigint "product_id", null: false
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "unit_price", precision: 12, scale: 2, null: false
    t.index ["product_id"], name: "index_receipt_products_on_product_id"
    t.index ["receipt_id", "product_id"], name: "index_receipt_products_on_receipt_id_and_product_id", unique: true
    t.index ["receipt_id"], name: "index_receipt_products_on_receipt_id"
    t.check_constraint "amount > 0", name: "receipt_products_amount_positive"
    t.check_constraint "unit_price > 0::numeric", name: "receipt_products_unit_price_positive"
  end

  create_table "receipts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "taxes", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "net_value", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total_value", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_receipts_on_user_id"
    t.check_constraint "net_value >= 0::numeric", name: "receipts_net_value_non_negative"
    t.check_constraint "taxes >= 0::numeric", name: "receipts_taxes_non_negative"
    t.check_constraint "total_value >= 0::numeric", name: "receipts_total_value_non_negative"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "clerk_id"
    t.index ["clerk_id"], name: "index_users_on_clerk_id", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "receipt_products", "products"
  add_foreign_key "receipt_products", "receipts"
  add_foreign_key "receipts", "users"
end
