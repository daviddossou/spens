# frozen_string_literal: true

class Budgets::RecurrenceFieldsComponent < ViewComponent::Base
  def initialize(frequency:, ends_on:, rollover:, expense:, debt: false, name_prefix: "budget_item", open: false, show_example: true)
    @frequency = frequency
    @ends_on = ends_on
    @rollover = rollover
    @expense = expense
    @debt = debt
    @name_prefix = name_prefix
    @open = open
    @show_example = show_example
  end

  private

  attr_reader :frequency, :ends_on, :rollover, :expense, :debt, :name_prefix, :open, :show_example
end
