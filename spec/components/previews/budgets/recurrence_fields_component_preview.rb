# frozen_string_literal: true

module Budgets
  # @label Recurrence Fields
  class RecurrenceFieldsComponentPreview < ViewComponent::Preview
    # A monthly expense with no end, collapsed
    def default
      render Budgets::RecurrenceFieldsComponent.new(frequency: "monthly", ends_on: nil, rollover: false, expense: true)
    end

    # Open, quarterly, ending on a date, carrying leftovers over
    def open_dated_quarterly
      render Budgets::RecurrenceFieldsComponent.new(
        frequency: "quarterly", ends_on: Date.current.next_year, rollover: true, expense: true, open: true
      )
    end

    # An income line: no rollover
    def income
      render Budgets::RecurrenceFieldsComponent.new(frequency: "monthly", ends_on: nil, rollover: false, expense: false, open: true)
    end

    # A debt repayment: always vital
    def debt
      render Budgets::RecurrenceFieldsComponent.new(
        frequency: "monthly", ends_on: Date.current >> 6, rollover: false, expense: false, debt: true, open: true
      )
    end

    # Month editor: another field namespace, no example line
    def budget_entry_namespace
      render Budgets::RecurrenceFieldsComponent.new(
        frequency: "monthly", ends_on: nil, rollover: false, expense: true, name_prefix: "budget_entry", open: true, show_example: false
      )
    end
  end
end
