# frozen_string_literal: true

class AddHierarchyToTransactionTypes < ActiveRecord::Migration[8.0]
  def change
    # Stable, locale-independent identity linking a per-space row to a taxonomy node
    # (config/transaction_taxonomy.yml). NULL = a free-text category the user created.
    add_column :transaction_types, :template_key, :string

    # Self-referential parent: a subcategory points at its parent category (one level deep).
    add_reference :transaction_types, :parent, type: :uuid, null: true,
                  foreign_key: { to_table: :transaction_types }

    # One row per template_key per space (parents and subcategories coexist under this).
    add_index :transaction_types, [ :space_id, :template_key ], unique: true,
              where: "template_key IS NOT NULL",
              name: "index_transaction_types_on_space_and_template_key"
  end
end
