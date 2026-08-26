class AddDeadlineToDebts < ActiveRecord::Migration[8.0]
  def change
    add_column :debts, :deadline, :date
  end
end
