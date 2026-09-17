# frozen_string_literal: true

module Budgets
  # @label Category Hero
  class CategoryHeroComponentPreview < ViewComponent::Preview
    # An envelope part-way through the month
    def in_progress
      render_hero(total: 20_000)
    end

    # Spent more than planned
    def over_budget
      render_hero(total: 60_000)
    end

    # Paid exactly on plan: the green check
    def celebrate
      render_hero(total: 50_000)
    end

    # An income category above its plan reads as a positive
    def income_above_plan
      render_hero(total: 120_000, planned: 100_000, kind: "income", name: "Salary", income: true)
    end

    # Nothing moved yet, with the usual debit day
    def expected_day
      render_hero(total: 0, transactions: [], usual_day: 5)
    end

    # No envelope yet: the average and a create button
    def no_envelope
      render_hero(entry: false, total: 20_000, average: 30_000)
    end

    # A sub-category counted on its parent's line
    def child_of_parent
      parent = TransactionType.new(id: SecureRandom.uuid, name: "Food", kind: "expense")
      category = TransactionType.new(id: SecureRandom.uuid, name: "Groceries", kind: "expense", parent: parent)
      parent_entry = build_entry(TransactionType.new(id: parent.id, name: "Food", kind: "expense"), 80_000)
      parent_progress = Budgets::LineProgress.new(entry: parent_entry, actual: 90_000)
      render_hero(entry: false, category: category, parent_progress: parent_progress, total: 20_000)
    end

    private

    def render_hero(total:, planned: 50_000, kind: "expense", name: "Groceries", income: false, average: 0,
                    transactions: Array.new(3), usual_day: nil, entry: true, category: nil, parent_progress: nil)
      category ||= TransactionType.new(id: SecureRandom.uuid, name: name, kind: kind)
      entry = entry ? build_entry(category, planned) : nil
      progress = entry && Budgets::LineProgress.new(entry: entry, actual: total)
      component = Budgets::CategoryHeroComponent.new(
        average: average, category: category, editable: true, entry: entry, parent_progress: parent_progress,
        progress: progress, total: total.to_f, transactions: transactions, usual_day: usual_day,
        income: income, month_slug: Date.current.strftime("%Y-%m")
      )
      render_with_template(template: "shared/space_context", locals: { component: component })
    end

    def build_entry(category, planned)
      item = BudgetItem.new(id: SecureRandom.uuid, kind: category.kind, amount: planned, frequency: "monthly", transaction_type: category)
      BudgetEntry.new(id: SecureRandom.uuid, kind: category.kind, month: Date.current.beginning_of_month,
                      planned_amount: planned, budget_item: item, transaction_type: category)
    end
  end
end
