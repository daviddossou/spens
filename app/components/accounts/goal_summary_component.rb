# frozen_string_literal: true

class Accounts::GoalSummaryComponent < ViewComponent::Base
  def initialize(account:, progress:)
    @account = account
    @progress = progress
  end

  private

  attr_reader :account, :progress

  delegate :account_money, to: :helpers
end
