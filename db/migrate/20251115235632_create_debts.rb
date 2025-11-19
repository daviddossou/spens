class CreateDebts < ActiveRecord::Migration[8.0]
  def change
    create_table :debts, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.float :total_lent, null: false, default: 0.0
      t.float :total_reimbursed, null: false, default: 0.0
      t.text :note
      t.string :status, null: false, default: "ongoing"
      t.string :direction, null: false, default: "lent"

      t.timestamps
    end

    add_index :debts, :status
  end
end
