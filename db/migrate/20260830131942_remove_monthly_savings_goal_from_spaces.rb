class RemoveMonthlySavingsGoalFromSpaces < ActiveRecord::Migration[8.0]
  def change
    remove_column :spaces, :monthly_savings_goal, :decimal, precision: 15, scale: 2
  end
end
