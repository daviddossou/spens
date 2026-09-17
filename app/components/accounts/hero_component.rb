# frozen_string_literal: true

class Accounts::HeroComponent < ViewComponent::Base
  def initialize(account:, last_transaction_date:)
    @account = account
    @last_transaction_date = last_transaction_date
  end

  private

  attr_reader :account, :last_transaction_date

  delegate :account_last_movement, :account_money, :money_negative?, to: :helpers
end
