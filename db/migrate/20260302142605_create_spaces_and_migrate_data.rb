# frozen_string_literal: true

class CreateSpacesAndMigrateData < ActiveRecord::Migration[8.0]
  def up
    # 1. Create spaces table
    create_table :spaces, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :currency, default: "XOF"
      t.string :country
      t.string :income_frequency
      t.string :main_income_source
      t.jsonb :financial_goals, default: []
      t.string :onboarding_current_step
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :spaces, "user_id, lower((name)::text)", unique: true, name: "index_spaces_on_user_id_and_lower_name"

    # 2. Add space_id to child tables
    add_reference :accounts, :space, type: :uuid
    add_reference :transaction_types, :space, type: :uuid
    add_reference :transactions, :space, type: :uuid
    add_reference :debts, :space, type: :uuid

    # 3. Data migration — create a default "Personal" space for each user
    execute <<-SQL
      INSERT INTO spaces (id, name, currency, country, income_frequency, main_income_source, financial_goals, onboarding_current_step, user_id, created_at, updated_at)
      SELECT gen_random_uuid(), 'Personal', currency, country, income_frequency, main_income_source, financial_goals, onboarding_current_step, id, NOW(), NOW()
      FROM users;
    SQL

    # Backfill space_id on all child tables
    execute "UPDATE accounts SET space_id = spaces.id FROM spaces WHERE accounts.user_id = spaces.user_id;"
    execute "UPDATE transaction_types SET space_id = spaces.id FROM spaces WHERE transaction_types.user_id = spaces.user_id;"
    execute "UPDATE transactions SET space_id = spaces.id FROM spaces WHERE transactions.user_id = spaces.user_id;"
    execute "UPDATE debts SET space_id = spaces.id FROM spaces WHERE debts.user_id = spaces.user_id;"

    # 4. Make space_id NOT NULL
    change_column_null :accounts, :space_id, false
    change_column_null :transaction_types, :space_id, false
    change_column_null :transactions, :space_id, false
    change_column_null :debts, :space_id, false

    # 5. Add foreign keys for space_id
    add_foreign_key :accounts, :spaces
    add_foreign_key :transaction_types, :spaces
    add_foreign_key :transactions, :spaces
    add_foreign_key :debts, :spaces

    # 6. Remove old user_id foreign keys from child tables
    remove_foreign_key :accounts, :users
    remove_foreign_key :transaction_types, :users
    remove_foreign_key :transactions, :users
    remove_foreign_key :debts, :users

    # 7. Drop old user_id indexes and columns from child tables
    remove_index :accounts, name: "index_accounts_on_lower_name_and_user_id"
    remove_index :accounts, name: "index_accounts_on_user_id"
    remove_index :transaction_types, name: "index_transaction_types_on_lower_name_user_and_kind"
    remove_index :transaction_types, name: "index_transaction_types_on_user_id"
    remove_index :transactions, name: "index_transactions_on_user_id"
    remove_index :debts, name: "index_debts_on_user_id"

    remove_column :accounts, :user_id
    remove_column :transaction_types, :user_id
    remove_column :transactions, :user_id
    remove_column :debts, :user_id

    # 8. Add new space-scoped uniqueness indexes
    add_index :accounts, "lower((name)::text), space_id", unique: true, name: "index_accounts_on_lower_name_and_space_id"
    add_index :transaction_types, "lower((name)::text), space_id, kind", unique: true, name: "index_transaction_types_on_lower_name_space_and_kind"

    # 9. Remove columns from users that moved to spaces
    remove_index :users, name: "index_users_on_country", if_exists: true
    remove_index :users, name: "index_users_on_currency", if_exists: true
    remove_index :users, name: "index_users_on_onboarding_current_step", if_exists: true

    remove_column :users, :currency
    remove_column :users, :country
    remove_column :users, :income_frequency
    remove_column :users, :main_income_source
    remove_column :users, :financial_goals
    remove_column :users, :onboarding_current_step
  end

  def down
    # Add columns back to users
    add_column :users, :currency, :string, default: "XOF"
    add_column :users, :country, :string
    add_column :users, :income_frequency, :string
    add_column :users, :main_income_source, :string
    add_column :users, :financial_goals, :jsonb, default: []
    add_column :users, :onboarding_current_step, :string

    add_index :users, :country
    add_index :users, :currency
    add_index :users, :onboarding_current_step

    # Add user_id back to child tables
    add_reference :accounts, :user, type: :uuid
    add_reference :transaction_types, :user, type: :uuid
    add_reference :transactions, :user, type: :uuid
    add_reference :debts, :user, type: :uuid

    # Backfill user_id from spaces
    execute "UPDATE accounts SET user_id = spaces.user_id FROM spaces WHERE accounts.space_id = spaces.id;"
    execute "UPDATE transaction_types SET user_id = spaces.user_id FROM spaces WHERE transaction_types.space_id = spaces.id;"
    execute "UPDATE transactions SET user_id = spaces.user_id FROM spaces WHERE transactions.space_id = spaces.id;"
    execute "UPDATE debts SET user_id = spaces.user_id FROM spaces WHERE debts.space_id = spaces.id;"

    # Backfill user columns from first space
    execute <<-SQL
      UPDATE users SET
        currency = s.currency,
        country = s.country,
        income_frequency = s.income_frequency,
        main_income_source = s.main_income_source,
        financial_goals = s.financial_goals,
        onboarding_current_step = s.onboarding_current_step
      FROM (
        SELECT DISTINCT ON (user_id) *
        FROM spaces
        ORDER BY user_id, created_at ASC
      ) s
      WHERE users.id = s.user_id;
    SQL

    change_column_null :accounts, :user_id, false
    change_column_null :transaction_types, :user_id, false
    change_column_null :transactions, :user_id, false
    change_column_null :debts, :user_id, false

    # Re-add user_id foreign keys
    add_foreign_key :accounts, :users
    add_foreign_key :transaction_types, :users
    add_foreign_key :transactions, :users
    add_foreign_key :debts, :users

    # Remove space_id foreign keys
    remove_foreign_key :accounts, :spaces
    remove_foreign_key :transaction_types, :spaces
    remove_foreign_key :transactions, :spaces
    remove_foreign_key :debts, :spaces

    # Drop space_id indexes and columns
    remove_index :accounts, name: "index_accounts_on_lower_name_and_space_id", if_exists: true
    remove_index :transaction_types, name: "index_transaction_types_on_lower_name_space_and_kind", if_exists: true

    remove_column :accounts, :space_id
    remove_column :transaction_types, :space_id
    remove_column :transactions, :space_id
    remove_column :debts, :space_id

    # Re-add original user_id indexes
    add_index :accounts, "lower((name)::text), user_id", unique: true, name: "index_accounts_on_lower_name_and_user_id"
    add_index :transaction_types, "lower((name)::text), user_id, kind", unique: true, name: "index_transaction_types_on_lower_name_user_and_kind"

    # Drop spaces table
    drop_table :spaces
  end
end
