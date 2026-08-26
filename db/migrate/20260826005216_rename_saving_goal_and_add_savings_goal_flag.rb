class RenameSavingGoalAndAddSavingsGoalFlag < ActiveRecord::Migration[8.0]
  # Decouple "this account is a savings goal" from its target amount so a goal can
  # be created and named before a target is set. The old saving_goal float doubled
  # as both; split it into an explicit boolean flag plus an optional amount.
  def change
    rename_column :accounts, :saving_goal, :savings_goal_amount
    rename_column :accounts, :saving_goal_deadline, :savings_goal_deadline
    # The amount is now optional (nil = no target yet), no longer defaulting to 0.
    change_column_default :accounts, :savings_goal_amount, from: 0.0, to: nil

    add_column :accounts, :savings_goal, :boolean, default: false, null: false
    # Flag is backfilled from existing amounts in a post-deploy task (release:run_after).
  end
end
