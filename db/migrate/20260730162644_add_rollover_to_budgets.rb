class AddRolloverToBudgets < ActiveRecord::Migration[8.0]
  def change
    add_column :budget_items, :rollover, :boolean, default: false, null: false
    add_column :budget_entries, :carried_amount, :decimal, precision: 15, scale: 2, default: 0, null: false
  end
end
