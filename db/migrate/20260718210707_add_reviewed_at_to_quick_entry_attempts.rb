class AddReviewedAtToQuickEntryAttempts < ActiveRecord::Migration[8.0]
  def change
    add_column :quick_entry_attempts, :reviewed_at, :datetime
    add_index :quick_entry_attempts, :reviewed_at
  end
end
