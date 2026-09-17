# frozen_string_literal: true

module Debts
  # @label Closed History
  class ClosedHistoryComponentPreview < ViewComponent::Preview
    # Settled and written-off debts, one person with two of them
    def default
      debts = [
        closed_debt("Awa", "lent", "paid", 15_000, updated_at: 3.days.ago),
        closed_debt("awa", "borrowed", "paid", 8_000, updated_at: 2.weeks.ago),
        closed_debt("Georges", "borrowed", "written_off", 5_000, updated_at: 1.month.ago),
        closed_debt("Myri", "lent", "written_off", 20_000, updated_at: 2.months.ago)
      ]
      groups = debts.group_by { |d| DebtRelation.normalize(d.name) }.values
      component = Debts::ClosedHistoryComponent.new(closed_debts: debts, closed_groups: groups)
      render_with_template(template: "shared/space_context", locals: { component: component })
    end

    # Only settled debts
    def settled_only
      debts = [ closed_debt("Awa", "lent", "paid", 15_000, updated_at: 3.days.ago) ]
      component = Debts::ClosedHistoryComponent.new(closed_debts: debts, closed_groups: [ debts ])
      render_with_template(template: "shared/space_context", locals: { component: component })
    end

    private

    def closed_debt(name, direction, status, total, updated_at:)
      Debt.new(id: SecureRandom.uuid, name: name, direction: direction, status: status, total_lent: total,
               total_reimbursed: (status == "paid" ? total : 0), updated_at: updated_at)
    end
  end
end
