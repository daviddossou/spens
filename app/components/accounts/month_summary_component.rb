# frozen_string_literal: true

class Accounts::MonthSummaryComponent < ViewComponent::Base
  def initialize(month_in:, month_out:)
    @month_in = month_in
    @month_out = month_out
  end

  private

  attr_reader :month_in, :month_out

  delegate :account_money, :money, to: :helpers
end
