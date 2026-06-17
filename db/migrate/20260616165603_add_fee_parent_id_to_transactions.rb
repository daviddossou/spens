class AddFeeParentIdToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :fee_parent_id, :uuid
    add_index :transactions, :fee_parent_id
  end
end
