# frozen_string_literal: true

namespace :backfill do
  desc "Flag existing accounts with a target amount as savings goals"
  task backfill_savings_goal_flag: :environment do
    count = Account.where(savings_goal: false)
                   .where("savings_goal_amount > 0")
                   .update_all(savings_goal: true)
    puts "[backfill] flagged #{count} account(s) as savings goals"
  end
end
