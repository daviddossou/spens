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

ActiveRecord::Schema[8.0].define(version: 2026_03_02_142605) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.float "saving_goal", default: 0.0
    t.float "balance", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "space_id", null: false
    t.index "lower((name)::text), space_id", name: "index_accounts_on_lower_name_and_space_id", unique: true
    t.index ["space_id"], name: "index_accounts_on_space_id"
  end

  create_table "debts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.float "total_lent", default: 0.0, null: false
    t.float "total_reimbursed", default: 0.0, null: false
    t.text "note"
    t.string "status", default: "ongoing", null: false
    t.string "direction", default: "lent", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "space_id", null: false
    t.index ["space_id"], name: "index_debts_on_space_id"
    t.index ["status"], name: "index_debts_on_status"
  end

  create_table "spaces", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "currency", default: "XOF"
    t.string "country"
    t.string "income_frequency"
    t.string "main_income_source"
    t.jsonb "financial_goals", default: []
    t.string "onboarding_current_step"
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "user_id, lower((name)::text)", name: "index_spaces_on_user_id_and_lower_name", unique: true
    t.index ["user_id"], name: "index_spaces_on_user_id"
  end

  create_table "transaction_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "kind", null: false
    t.float "budget_goal", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "space_id", null: false
    t.index "lower((name)::text), space_id, kind", name: "index_transaction_types_on_lower_name_space_and_kind", unique: true
    t.index ["kind"], name: "index_transaction_types_on_kind"
    t.index ["space_id"], name: "index_transaction_types_on_space_id"
  end

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "description", null: false
    t.text "note"
    t.float "amount", null: false
    t.date "transaction_date", null: false
    t.uuid "transaction_type_id", null: false
    t.uuid "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "debt_id"
    t.uuid "space_id", null: false
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["debt_id"], name: "index_transactions_on_debt_id"
    t.index ["space_id"], name: "index_transactions_on_space_id"
    t.index ["transaction_date"], name: "index_transactions_on_transaction_date"
    t.index ["transaction_type_id"], name: "index_transactions_on_transaction_type_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "otp_code"
    t.datetime "otp_sent_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounts", "spaces"
  add_foreign_key "debts", "spaces"
  add_foreign_key "spaces", "users"
  add_foreign_key "transaction_types", "spaces"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "debts"
  add_foreign_key "transactions", "spaces"
  add_foreign_key "transactions", "transaction_types"
end
