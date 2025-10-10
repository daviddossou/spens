class CreateTransactionTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :transaction_types, id: :uuid do |t|
      t.string :name, null: false
      t.string :kind, null: false
      t.float :budget_goal, default: 0.0
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :transaction_types, :kind
  end
end
