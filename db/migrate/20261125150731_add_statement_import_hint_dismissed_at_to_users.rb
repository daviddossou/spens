class AddStatementImportHintDismissedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :statement_import_hint_dismissed_at, :datetime
  end
end
