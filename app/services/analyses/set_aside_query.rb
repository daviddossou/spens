# frozen_string_literal: true

module Analyses
  # Money put aside per month: the NET transfer flow into set-aside accounts
  # (in minus out — a withdrawal lowers the figure). The streak counts the
  # consecutive positive months ending today.
  class SetAsideQuery
    def initialize(space:)
      @space = space
    end

    def any_account?
      set_aside_ids.any?
    end

    def monthly_net(month)
      range = month.beginning_of_month..month.end_of_month
      inflow(range) - outflow(range)
    end

    def last_three
      bom = Date.current.beginning_of_month
      [ bom << 2, bom << 1, bom ].map { |m| [ m, monthly_net(m) ] }
    end

    def streak
      count = 0
      month = Date.current.beginning_of_month
      while count < 36 && monthly_net(month).positive?
        count += 1
        month = month << 1
      end
      count
    end

    private

    def set_aside_ids
      @set_aside_ids ||= @space.accounts.set_aside.pluck(:id)
    end

    def inflow(range)
      flow("transfer_in", range)
    end

    def outflow(range)
      flow("transfer_out", range)
    end

    def flow(kind, range)
      @space.transactions.joins(:transaction_type)
            .where(account_id: set_aside_ids, transaction_date: range,
                   transaction_types: { kind: kind })
            .sum("ABS(transactions.amount)").to_f.round(2)
    end
  end
end
