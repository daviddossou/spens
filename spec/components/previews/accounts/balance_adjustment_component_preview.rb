# frozen_string_literal: true

module Accounts
  # @label Balance adjustment
  class BalanceAdjustmentComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # The gap block as it ships: hidden until the account-form controller reveals it
    def default
      render with_helpers(Accounts::BalanceAdjustmentComponent.new(account: build_account))
    end

    # Forced visible to see the three options
    def revealed
      render_with_template(locals: { component: with_helpers(Accounts::BalanceAdjustmentComponent.new(account: build_account)) })
    end
  end
end
