class AddSavingGoalDeadlineToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :saving_goal_deadline, :date
  end
end
