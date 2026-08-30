class AddLabelToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :label, :string
  end
end
