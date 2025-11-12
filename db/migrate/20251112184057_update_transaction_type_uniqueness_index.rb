class UpdateTransactionTypeUniquenessIndex < ActiveRecord::Migration[8.0]
  def change
    # Remove the old unique index on (lower(name), user_id)
    remove_index :transaction_types, name: "index_transaction_types_on_lower_name_and_user_id"

    # Add new unique index on (lower(name), user_id, kind)
    add_index :transaction_types,
              "lower((name)::text), user_id, kind",
              unique: true,
              name: "index_transaction_types_on_lower_name_user_and_kind"
  end
end
