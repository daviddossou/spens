# frozen_string_literal: true

class Budgets::SectionComponent < ViewComponent::Base
  def initialize(actuals_by_entry:, editable:, mode:, section:, entries:, planned:, actual:, short_month:)
    @actuals_by_entry = actuals_by_entry
    @editable = editable
    @mode = mode
    @section = section
    @entries = entries
    @planned = planned
    @actual = actual
    @short_month = short_month
  end

  private

  attr_reader :actuals_by_entry, :editable, :mode, :section, :entries, :planned, :actual, :short_month

  delegate :current_space, :money, to: :helpers
end
