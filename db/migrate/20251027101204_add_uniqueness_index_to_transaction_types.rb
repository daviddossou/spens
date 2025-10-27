class AddUniquenessIndexToTransactionTypes < ActiveRecord::Migration[8.0]
  def change
    # Add unique index for transaction type name scoped to user_id (case-insensitive)
    add_index :transaction_types, 'lower(name), user_id', unique: true, name: 'index_transaction_types_on_lower_name_and_user_id'
  end
end
