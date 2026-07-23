class CreateBudgetEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :budget_entries, id: :uuid do |t|
      t.references :space, null: false, foreign_key: true, type: :uuid
      t.references :budget_item, null: false, foreign_key: true, type: :uuid
      t.references :transaction_type, foreign_key: true, type: :uuid
      t.date :month, null: false
      t.string :kind, null: false
      t.decimal :planned_amount, precision: 15, scale: 2, null: false

      t.timestamps
    end

    add_index :budget_entries, [ :space_id, :budget_item_id, :month ],
              unique: true, name: "index_budget_entries_on_space_item_month"
    add_index :budget_entries, [ :space_id, :month ]
  end
end
