# frozen_string_literal: true

module Budgets
  # @label Unplanned Section
  class UnplannedSectionComponentPreview < ViewComponent::Preview
    # Live month: a recurring expense, a one-off income and a transfer
    def default
      render_section(read_only: false)
    end

    # Closed month: the same, without the plan-it action
    def read_only
      render_section(read_only: true)
    end

    private

    def render_section(read_only:)
      taxi = TransactionType.new(id: SecureRandom.uuid, name: "Taxi", kind: "expense")
      bonus = TransactionType.new(id: SecureRandom.uuid, name: "Bonus", kind: "income")
      unplanned = {
        expense: { taxi => { amount: 12_000.0, prev: 3_000.0 } },
        income: { bonus => { amount: 50_000.0, prev: 0.0 } },
        transfers: [ { from: Account.new(name: "Bank"), to: Account.new(name: "Savings"), amount: 20_000.0, prev: 0.0 } ]
      }
      component = Budgets::UnplannedSectionComponent.new(month: Date.current.beginning_of_month, unplanned: unplanned, read_only: read_only)
      render_with_template(template: "shared/space_context", locals: { component: component })
    end
  end
end
