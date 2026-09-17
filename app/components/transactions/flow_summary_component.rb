# frozen_string_literal: true

class Transactions::FlowSummaryComponent < ViewComponent::Base
  def initialize(currency:, money_in:, money_out:)
    @currency = currency
    @money_in = money_in
    @money_out = money_out
  end

  private

  attr_reader :currency, :money_in, :money_out

  delegate :money, to: :helpers
end
