class AddUniquenessIndexToAccounts < ActiveRecord::Migration[8.0]
  def change
    # Add unique index for account name scoped to user_id (case-insensitive)
    add_index :accounts, 'lower(name), user_id', unique: true, name: 'index_accounts_on_lower_name_and_user_id'
  end
end
