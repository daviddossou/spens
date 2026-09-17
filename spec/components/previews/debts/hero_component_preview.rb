# frozen_string_literal: true

module Debts
  # @label Hero
  class HeroComponentPreview < ViewComponent::Preview
    # Someone owes you, a quarter repaid
    def lent
      render Debts::HeroComponent.new(debt: debt("lent", 100_000, 25_000), currency: "XOF")
    end

    # You owe someone, nothing repaid yet
    def borrowed
      render Debts::HeroComponent.new(debt: debt("borrowed", 30_000, 0), currency: "XOF")
    end

    # No amount set yet: no gauge
    def no_amount
      render Debts::HeroComponent.new(debt: debt("lent", 0, 0), currency: "EUR")
    end

    private

    def debt(direction, total, reimbursed)
      Debt.new(name: "Myri", direction: direction, total_lent: total, total_reimbursed: reimbursed)
    end
  end
end
