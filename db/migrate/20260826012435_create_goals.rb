class CreateGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :goals, id: :uuid do |t|
      t.string :name, null: false
      t.decimal :target_amount, precision: 15, scale: 2
      t.date :deadline
      # One goal per account (the account is the goal's pot).
      t.references :account, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.references :space, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
