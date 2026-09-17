# frozen_string_literal: true

module Accounts
  # @label Month summary
  class MonthSummaryComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # More in than out
    def default
      render with_helpers(Accounts::MonthSummaryComponent.new(month_in: 250_000, month_out: 80_000))
    end

    # More out than in
    def negative_net
      render with_helpers(Accounts::MonthSummaryComponent.new(month_in: 50_000, month_out: 120_000))
    end

    # A quiet month
    def empty
      render with_helpers(Accounts::MonthSummaryComponent.new(month_in: 0, month_out: 0))
    end
  end
end
