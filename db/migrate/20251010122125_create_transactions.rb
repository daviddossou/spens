class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions, id: :uuid do |t|
      t.string :description, null: false
      t.text :note
      t.float :amount, null: false
      t.date :transaction_date, null: false
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :transaction_type, null: false, foreign_key: true, type: :uuid
      t.references :account, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :transactions, :transaction_date
  end
end
