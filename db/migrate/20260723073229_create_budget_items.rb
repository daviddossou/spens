class CreateBudgetItems < ActiveRecord::Migration[8.0]
  def change
    create_table :budget_items, id: :uuid do |t|
      t.references :space, null: false, foreign_key: true, type: :uuid
      # Category for income/expense lines; transfer and debt lines use the
      # account pair / debt reference below instead.
      t.references :transaction_type, foreign_key: true, type: :uuid
      t.references :from_account, foreign_key: { to_table: :accounts }, type: :uuid
      t.references :to_account, foreign_key: { to_table: :accounts }, type: :uuid
      t.references :debt, foreign_key: true, type: :uuid
      t.string :kind, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :frequency, null: false
      t.date :starts_on, null: false
      t.date :ends_on
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :budget_items, [ :space_id, :transaction_type_id ],
              unique: true, where: "active AND transaction_type_id IS NOT NULL",
              name: "index_budget_items_on_space_and_type_active"
    add_index :budget_items, [ :space_id, :from_account_id, :to_account_id ],
              unique: true, where: "active AND from_account_id IS NOT NULL",
              name: "index_budget_items_on_space_and_transfer_active"
    add_index :budget_items, [ :space_id, :debt_id, :kind ],
              unique: true, where: "active AND debt_id IS NOT NULL",
              name: "index_budget_items_on_space_and_debt_active"
  end
end
