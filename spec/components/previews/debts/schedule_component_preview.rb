# frozen_string_literal: true

module Debts
  # @label Schedule
  class ScheduleComponentPreview < ViewComponent::Preview
    # A loan repaid to you in monthly installments
    def incoming
      render_schedule(incoming: true, installments: 4)
    end

    # A debt you repay, one installment left
    def outgoing_last_installment
      render_schedule(incoming: false, installments: 1)
    end

    private

    def render_schedule(incoming:, installments:)
      debt = Debt.new(id: SecureRandom.uuid, name: "Myri", direction: incoming ? "lent" : "borrowed", total_lent: 80_000)
      start = Date.current.beginning_of_month.next_month
      schedule = { monthly: 20_000, ends_on: start >> (installments - 1), installments: installments, incoming: incoming }
      component = Debts::ScheduleComponent.new(debt: debt, schedule: schedule)
      render_with_template(template: "shared/space_context", locals: { component: component })
    end
  end
end
