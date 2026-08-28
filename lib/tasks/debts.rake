# frozen_string_literal: true

namespace :debts do
  desc "Close debts that are fully reimbursed but still marked ongoing (pre-callback data)"
  task settle_fully_reimbursed: :environment do
    scope = Debt.ongoing.where("total_lent > 0 AND total_reimbursed >= total_lent")
    count = scope.update_all(status: "paid", updated_at: Time.current)
    Rails.logger.info "[debts:settle_fully_reimbursed] closed #{count} fully-reimbursed debt(s)"
  end
end
