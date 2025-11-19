class AddDebtIdToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :transactions, :debt, null: true, foreign_key: true, type: :uuid
  end
end
