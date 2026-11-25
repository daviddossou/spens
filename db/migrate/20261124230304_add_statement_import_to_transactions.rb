class AddStatementImportToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :statement_import, null: true, foreign_key: { on_delete: :nullify }, type: :uuid
  end
end
