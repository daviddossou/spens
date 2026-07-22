class AddMonthlySavingsGoalToSpaces < ActiveRecord::Migration[8.0]
  def change
    add_column :spaces, :monthly_savings_goal, :decimal, precision: 15, scale: 2
  end
end
