class AddPreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :currency, :string, default: 'XOF'
    add_column :users, :country, :string
    add_column :users, :income_frequency, :string
    add_column :users, :main_income_source, :string
    add_column :users, :financial_goals, :jsonb, default: []
    add_column :users, :onboarding_current_step, :string

    add_index :users, :currency
    add_index :users, :country
    add_index :users, :onboarding_current_step
  end
end
