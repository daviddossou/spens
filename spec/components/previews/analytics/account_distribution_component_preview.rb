# frozen_string_literal: true

require "ostruct"
require_relative "preview_money"

module Analytics
  # @label Account distribution
  class AccountDistributionComponentPreview < ViewComponent::Preview
    include Analytics::PreviewMoney

    # Three accounts, each with its own row
    def default
      render with_money(Analytics::AccountDistributionComponent.new(accounts: accounts.first(3)))
    end

    # Five accounts: three rows and a muted "others" row
    def more_than_three
      render with_money(Analytics::AccountDistributionComponent.new(accounts: accounts))
    end

    # One account owns the whole stack
    def single_account
      render with_money(Analytics::AccountDistributionComponent.new(accounts: accounts.first(1)))
    end

    # No account with a positive balance: nothing renders
    def empty
      render with_money(Analytics::AccountDistributionComponent.new(accounts: []))
    end

    private

    def accounts
      [ [ "Bank", 850_000.0 ], [ "Mobile money", 210_000.0 ], [ "Cash", 45_000.0 ], [ "Tontine", 30_000.0 ], [ "Savings", 12_500.0 ] ]
        .map { |name, balance| OpenStruct.new(name: name, balance: balance) }
    end
  end
end
