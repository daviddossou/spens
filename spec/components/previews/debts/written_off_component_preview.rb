# frozen_string_literal: true

module Debts
  # @label Written Off
  class WrittenOffComponentPreview < ViewComponent::Preview
    # A loan written off after a partial repayment
    def lent_partially_recovered
      render_state(Debt.new(name: "Myri", direction: "lent", status: "written_off", total_lent: 50_000, total_reimbursed: 15_000, updated_at: 2.weeks.ago))
    end

    # A debt forgiven before anything was repaid
    def borrowed_forgiven
      render_state(Debt.new(name: "Georges", direction: "borrowed", status: "written_off", total_lent: 8_000, total_reimbursed: 0, updated_at: 1.month.ago))
    end

    private

    def render_state(debt)
      render_with_template(template: "shared/space_context", locals: { component: Debts::WrittenOffComponent.new(debt: debt) })
    end
  end
end
