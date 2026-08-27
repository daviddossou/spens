class DropSavingsGoalColumnsFromAccounts < ActiveRecord::Migration[8.0]
  # Second phase of the Goal-model move. Goal name/amount/deadline now live on the
  # goals table, and the backfill (backfill:savings_goals_to_model) has moved
  # existing account savings goals onto it. Safe to drop the old columns now.
  #
  # Ship this ONLY after the release that added the goals table + backfill has
  # deployed and its post-deploy task has run.
  # Idempotent: some environments already dropped these columns in an earlier state,
  # so only touch a column when it's actually present.
  def up
    remove_column :accounts, :savings_goal if column_exists?(:accounts, :savings_goal)
    remove_column :accounts, :savings_goal_amount if column_exists?(:accounts, :savings_goal_amount)
    remove_column :accounts, :savings_goal_deadline if column_exists?(:accounts, :savings_goal_deadline)
  end

  def down
    add_column :accounts, :savings_goal, :boolean, default: false, null: false unless column_exists?(:accounts, :savings_goal)
    add_column :accounts, :savings_goal_amount, :decimal, precision: 15, scale: 2 unless column_exists?(:accounts, :savings_goal_amount)
    add_column :accounts, :savings_goal_deadline, :date unless column_exists?(:accounts, :savings_goal_deadline)
  end
end
