# frozen_string_literal: true

class Accounts::RowComponent < ViewComponent::Base
  def initialize(account:)
    @account = account
  end

  private

  attr_reader :account

  delegate :account_money, :money_negative?, to: :helpers
end
