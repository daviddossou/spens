# frozen_string_literal: true

namespace :activation do
  # One-off: milestones reached before the ActivationMilestone ledger existed, sent to PostHog
  # at the date they happened. month_2 is not derivable; it fires on the next sign-in.
  desc "Backfill activation milestones from existing data"
  task backfill: :environment do
    User.find_each do |user|
      owned = Space.where(user_id: user.id).select(:id)
      transactions = Transaction.where(user_id: user.id).or(Transaction.where(user_id: nil, space_id: owned))
      entries = BudgetEntry.where(space_id: owned).group(:space_id, :month)

      income = entries.income.minimum(:created_at)
      budget_complete = entries.expense.minimum(:created_at)
        .filter_map { |key, at| [ at, income[key] ].max if income[key] }.min

      {
        first_account: Account.where(user_id: user.id).or(Account.where(user_id: nil, space_id: owned)).minimum(:created_at),
        first_transaction: transactions.minimum(:created_at),
        first_saving: transactions.joins(:transaction_type, account: :goal)
          .where(transaction_types: { kind: "transfer_in" }).minimum("transactions.created_at"),
        first_goal: Goal.where(space_id: owned).minimum(:created_at),
        budget_complete: budget_complete
      }.each { |milestone, at| Activation.record(user, milestone, at: at) if at }
    end
  end
end
