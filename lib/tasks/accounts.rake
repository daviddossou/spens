# frozen_string_literal: true

namespace :accounts do
  desc "Mark every account that carries a goal as set aside"
  task mark_goal_accounts_set_aside: :environment do
    # A goal is now the app's definition of money set aside, and the Goal model
    # keeps the flag in step from here on. This catches the accounts whose goal
    # predates that rule — without it their savings stay invisible to the
    # dashboard's "mis de côté" and to the budget's committed line.
    scope = Account.where(set_aside: false).where(id: Goal.select(:account_id))
    count = scope.count
    scope.update_all(set_aside: true)
    puts "marked #{count} goal account(s) as set aside"
  end
end
