# frozen_string_literal: true

class Accounts::BalanceAdjustmentComponent < ViewComponent::Base
  def initialize(account:)
    @account = account
  end

  private

  attr_reader :account
end
