class AddArchivedAtToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :archived_at, :datetime
    add_index :accounts, :archived_at
  end
end
