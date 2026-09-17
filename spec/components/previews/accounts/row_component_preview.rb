# frozen_string_literal: true

module Accounts
  # @label Account row
  class RowComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # An everyday account
    def default
      render with_helpers(Accounts::RowComponent.new(account: build_account))
    end

    # Overdrawn
    def negative_balance
      render with_helpers(Accounts::RowComponent.new(account: build_account(name: "Bank", balance: -3_500)))
    end

    # A savings account carrying a goal with a target
    def with_goal
      account = build_account(name: "Savings", balance: 145_000)
      build_goal(account, name: "Trip", target_amount: 580_000)
      render with_helpers(Accounts::RowComponent.new(account: account))
    end

    # A goal without a target: no promise line
    def goal_without_target
      account = build_account(name: "Savings", balance: 60_000)
      build_goal(account, name: "Someday", target_amount: nil, deadline: nil)
      render with_helpers(Accounts::RowComponent.new(account: account))
    end

    # The list as on the accounts page
    def list
      accounts = [ build_account, build_account(name: "Cash", balance: 8_000), build_account(name: "Bank", balance: -3_500) ]
      savings = build_account(name: "Savings", balance: 145_000)
      build_goal(savings, name: "Trip", target_amount: 580_000)
      components = (accounts + [ savings ]).map { |account| with_helpers(Accounts::RowComponent.new(account: account)) }
      render_with_template(locals: { components: components })
    end
  end
end
