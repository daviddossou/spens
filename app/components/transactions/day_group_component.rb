# frozen_string_literal: true

class Transactions::DayGroupComponent < ViewComponent::Base
  def initialize(date:, transactions:, day_total_scope: :space, category: nil, subcategory_hint: false)
    @date = date
    @transactions = transactions
    @day_total_scope = day_total_scope
    @category = category
    @subcategory_hint = subcategory_hint
  end

  private

  attr_reader :date, :transactions, :day_total_scope, :category, :subcategory_hint

  delegate :money, :movement_day_total, to: :helpers
end
