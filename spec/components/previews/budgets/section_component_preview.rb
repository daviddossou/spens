# frozen_string_literal: true

module Budgets
  # @label Section
  class SectionComponentPreview < ViewComponent::Preview
    # Expenses in the live month
    def live
      render_section(mode: :live)
    end

    # Expenses read as a plan
    def plan
      render_section(mode: :plan)
    end

    # A closed month: rows are read only
    def read_only
      render_section(mode: :wrap_up, editable: false)
    end

    # No line this month
    def empty
      render_section(mode: :live, entries: [], actuals: {})
    end

    private

    def render_section(mode:, editable: true, entries: default_entries, actuals: nil)
      actuals ||= entries.zip([ 30_000, 5_000, 12_000 ]).to_h
      component = Budgets::SectionComponent.new(
        actuals_by_entry: actuals, editable: editable, mode: mode, section: :expense, entries: entries,
        planned: entries.sum(&:planned_amount), actual: actuals.values.sum, short_month: I18n.l(Date.current, format: "%B")
      )
      render_with_template(template: "shared/space_context", locals: { component: component })
    end

    def default_entries
      [ [ "Rent", 30_000, true ], [ "Groceries", 20_000, true ], [ "Restaurants", 10_000, false ] ].map do |name, amount, essential|
        type = TransactionType.new(id: SecureRandom.uuid, name: name, kind: "expense")
        item = BudgetItem.new(id: SecureRandom.uuid, kind: "expense", amount: amount, frequency: "monthly", essential: essential, transaction_type: type)
        BudgetEntry.new(id: SecureRandom.uuid, kind: "expense", month: Date.current.beginning_of_month,
                        planned_amount: amount, budget_item: item, transaction_type: type)
      end
    end
  end
end
