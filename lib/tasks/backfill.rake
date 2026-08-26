# frozen_string_literal: true

namespace :backfill do
  # Move existing per-account savings goals onto the goals table. Runs post-deploy
  # (release:run_after), BEFORE the account savings_goal_* columns are dropped in a
  # later release. Idempotent: skips accounts that already have a goal.
  desc "Create Goal rows from accounts' savings_goal_* columns"
  task savings_goals_to_model: :environment do
    scope = Account.where("savings_goal_amount > 0 OR savings_goal = true")
    created = 0

    scope.find_each do |account|
      next if Goal.exists?(account_id: account.id)

      Goal.create!(
        space_id: account.space_id,
        account_id: account.id,
        name: account.name,
        target_amount: account.savings_goal_amount,
        deadline: account.savings_goal_deadline
      )
      created += 1
    end

    puts "[backfill] created #{created} goal(s) from account savings goals"
  end
end
