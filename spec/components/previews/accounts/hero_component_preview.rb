# frozen_string_literal: true

module Accounts
  # @label Account hero
  class HeroComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # An everyday account with a recent movement
    def default
      render with_helpers(Accounts::HeroComponent.new(account: build_account, last_transaction_date: Date.current - 3))
    end

    # Moved today
    def moved_today
      render with_helpers(Accounts::HeroComponent.new(account: build_account, last_transaction_date: Date.current))
    end

    # Never used yet
    def no_movement
      render with_helpers(Accounts::HeroComponent.new(account: build_account(balance: 0), last_transaction_date: nil))
    end

    # Overdrawn
    def negative_balance
      render with_helpers(Accounts::HeroComponent.new(account: build_account(balance: -12_000), last_transaction_date: Date.current - 1))
    end

    # An account promised to a goal
    def with_goal
      account = build_account(name: "Savings", balance: 200_000)
      build_goal(account)
      render with_helpers(Accounts::HeroComponent.new(account: account, last_transaction_date: Date.current))
    end
  end
end
