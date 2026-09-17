# frozen_string_literal: true

class Debts::ClosedHistoryComponent < ViewComponent::Base
  def initialize(closed_debts:, closed_groups:)
    @closed_groups = closed_groups
    @closed_debts = closed_debts
  end

  private

  attr_reader :closed_debts, :closed_groups

  delegate :closed_debt_row_subtitle, :closed_debt_short_tag, :closed_debts_breakdown, :money, to: :helpers
end
