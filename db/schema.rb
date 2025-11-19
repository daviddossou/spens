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

ActiveRecord::Schema[8.0].define(version: 2025_11_19_183109) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.float "saving_goal", default: 0.0
    t.float "balance", default: 0.0, null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text), user_id", name: "index_accounts_on_lower_name_and_user_id", unique: true
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "debts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.float "total_lent", default: 0.0, null: false
    t.float "total_reimbursed", default: 0.0, null: false
    t.text "note"
    t.string "status", default: "ongoing", null: false
    t.string "direction", default: "lent", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_debts_on_status"
    t.index ["user_id"], name: "index_debts_on_user_id"
  end

  create_table "transaction_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "kind", null: false
    t.float "budget_goal", default: 0.0
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text), user_id, kind", name: "index_transaction_types_on_lower_name_user_and_kind", unique: true
    t.index ["kind"], name: "index_transaction_types_on_kind"
    t.index ["user_id"], name: "index_transaction_types_on_user_id"
  end

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "description", null: false
    t.text "note"
    t.float "amount", null: false
    t.date "transaction_date", null: false
    t.uuid "user_id", null: false
    t.uuid "transaction_type_id", null: false
    t.uuid "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "debt_id"
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["debt_id"], name: "index_transactions_on_debt_id"
    t.index ["transaction_date"], name: "index_transactions_on_transaction_date"
    t.index ["transaction_type_id"], name: "index_transactions_on_transaction_type_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
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
    t.string "currency", default: "XOF"
    t.string "country"
    t.string "income_frequency"
    t.string "main_income_source"
    t.jsonb "financial_goals", default: []
    t.string "onboarding_current_step"
    t.index ["country"], name: "index_users_on_country"
    t.index ["currency"], name: "index_users_on_currency"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["onboarding_current_step"], name: "index_users_on_onboarding_current_step"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "debts", "users"
  add_foreign_key "transaction_types", "users"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "debts"
  add_foreign_key "transactions", "transaction_types"
  add_foreign_key "transactions", "users"
end
