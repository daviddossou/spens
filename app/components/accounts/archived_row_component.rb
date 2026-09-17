# frozen_string_literal: true

class Accounts::ArchivedRowComponent < ViewComponent::Base
  def initialize(account:)
    @account = account
  end

  private

  attr_reader :account

  delegate :account_money, to: :helpers
end
