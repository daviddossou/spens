# frozen_string_literal: true

require "ostruct"
require_relative "preview_money"

module Analytics
  # @label Savings history
  class SavingsHistoryComponentPreview < ViewComponent::Preview
    include Analytics::PreviewMoney

    # Three positive months in a row
    def default
      render history([ 20_000.0, 35_000.0, 25_000.0 ], streak: 3)
    end

    # The habit just started: one month, no streak
    def first_month
      render history([ 0.0, 0.0, 15_000.0 ], streak: 1)
    end

    # A withdrawal this month
    def withdrawal
      render history([ 30_000.0, 30_000.0, -12_000.0 ], streak: 0)
    end

    # No set-aside account: nothing renders
    def empty
      render with_money(Analytics::SavingsHistoryComponent.new(set_aside: OpenStruct.new(any_account?: false)))
    end

    private

    def history(nets, streak:)
      bom = Date.current.beginning_of_month
      months = [ bom << 2, bom << 1, bom ].zip(nets)
      with_money(Analytics::SavingsHistoryComponent.new(set_aside: OpenStruct.new(any_account?: true, last_three: months, streak: streak)))
    end
  end
end
