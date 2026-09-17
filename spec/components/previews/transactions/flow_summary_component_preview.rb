# frozen_string_literal: true

module Transactions
  # @label Flow summary
  class FlowSummaryComponentPreview < ViewComponent::Preview
    # Money in and out this month
    def default
      render Transactions::FlowSummaryComponent.new(currency: "XOF", money_in: 450_000, money_out: 187_500)
    end

    # Nothing moved yet
    def empty
      render Transactions::FlowSummaryComponent.new(currency: "XOF", money_in: 0, money_out: 0)
    end

    # Another currency, with cents
    def euros
      render Transactions::FlowSummaryComponent.new(currency: "EUR", money_in: 2_500, money_out: 1_200.5)
    end
  end
end
