class DropSavingsGoalColumnsFromAccounts < ActiveRecord::Migration[8.0]
  # Second phase of the Goal-model migration. Goal name/amount/deadline now live
  # on the goals table; the backfill (backfill:savings_goals_to_model) has moved
  # existing account savings goals onto it. Safe to drop the old columns now.
  #
  # Ship this ONLY after the release that added the goals table + backfill has
  # deployed and its post-deploy task has run.
  def change
    remove_column :accounts, :savings_goal, :boolean, default: false, null: false
    remove_column :accounts, :savings_goal_amount, :decimal, precision: 15, scale: 2
    remove_column :accounts, :savings_goal_deadline, :date
  end
end
