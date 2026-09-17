# frozen_string_literal: true

class Budgets::VitalConfortComponent < ViewComponent::Base
  def initialize(actual_confort:, actual_vital:, days_remaining:, planned_confort:, planned_expense_total:, planned_vital:, reste_a_depenser:, mode:)
    @actual_confort = actual_confort
    @actual_vital = actual_vital
    @days_remaining = days_remaining
    @planned_confort = planned_confort
    @planned_expense_total = planned_expense_total
    @planned_vital = planned_vital
    @reste_a_depenser = reste_a_depenser
    @mode = mode
  end

  private

  attr_reader :actual_confort, :actual_vital, :days_remaining, :planned_confort, :planned_expense_total, :planned_vital, :reste_a_depenser, :mode

  delegate :money, to: :helpers
end
