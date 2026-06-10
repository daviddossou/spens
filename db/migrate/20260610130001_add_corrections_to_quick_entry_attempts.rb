# frozen_string_literal: true

class AddCorrectionsToQuickEntryAttempts < ActiveRecord::Migration[8.0]
  def change
    add_column :quick_entry_attempts, :corrections, :jsonb
  end
end
