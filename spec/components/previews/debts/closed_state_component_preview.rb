# frozen_string_literal: true

module Debts
  # @label Closed State
  class ClosedStateComponentPreview < ViewComponent::Preview
    # A loan fully repaid
    def settled
      render_state(Debt.new(name: "Awa", direction: "lent", status: "paid", total_lent: 15_000, total_reimbursed: 15_000))
    end

    # A loan written off after a partial repayment
    def written_off_lent
      render_state(Debt.new(name: "Myri", direction: "lent", status: "written_off", total_lent: 20_000, total_reimbursed: 5_000))
    end

    # A debt forgiven before anything was repaid
    def forgiven_borrowed
      render_state(Debt.new(name: "Georges", direction: "borrowed", status: "written_off", total_lent: 5_000, total_reimbursed: 0))
    end

    private

    def render_state(debt)
      render_with_template(template: "shared/space_context", locals: { component: Debts::ClosedStateComponent.new(debt: debt) })
    end
  end
end
