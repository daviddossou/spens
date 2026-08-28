# frozen_string_literal: true

module Debts
  # The detail-page hero for an ongoing debt: a centered, direction-aware card
  # that names the relationship ("Myri owes you" / "You owe Myri"), shows the
  # remaining balance big and colored by direction, and a repayment gauge.
  class HeroComponent < ViewComponent::Base
    def initialize(debt:, currency:)
      @debt = debt
      @currency = currency
    end

    def direction_key
      @debt.lent? ? "lent" : "borrowed"
    end

    def remaining
      @debt.remaining_balance
    end

    def target_set?
      @debt.total_lent.to_f.positive?
    end

    def percentage
      return 0 unless target_set?

      [ [ (@debt.total_reimbursed.to_f / @debt.total_lent.to_f * 100).round, 100 ].min, 0 ].max
    end

    def money(value)
      helpers.smart_format_money(value, @currency, sign: :never)
    end
  end
end
