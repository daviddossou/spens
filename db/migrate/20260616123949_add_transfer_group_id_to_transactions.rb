class AddTransferGroupIdToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :transfer_group_id, :uuid
    add_index :transactions, :transfer_group_id
  end
end
