class AddMinedAtToQuickEntryAttempts < ActiveRecord::Migration[8.0]
  def change
    add_column :quick_entry_attempts, :mined_at, :datetime
    add_index :quick_entry_attempts, :mined_at
  end
end
