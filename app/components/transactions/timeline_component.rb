# frozen_string_literal: true

class Transactions::TimelineComponent < ViewComponent::Base
  def initialize(grouped_transactions:, day_total_scope: :space)
    @grouped_transactions = grouped_transactions
    @day_total_scope = day_total_scope
  end

  private

  attr_reader :grouped_transactions, :day_total_scope
end
