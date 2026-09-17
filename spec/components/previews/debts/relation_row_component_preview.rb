# frozen_string_literal: true

module Debts
  # @label Relation Row
  class RelationRowComponentPreview < ViewComponent::Preview
    # A loan a quarter repaid: the bar shows the progress
    def lent_in_progress
      render_row([ debt("Myri Diop", "lent", 100_000, 25_000) ])
    end

    # A debt you owe, nothing repaid yet: no bar
    def borrowed_untouched
      render_row([ debt("Ali", "borrowed", 5_000, 0) ])
    end

    # Money flows both ways: the net, with both sides spelled out
    def two_way
      render_row([ debt("Myri Diop", "lent", 100_000, 25_000), debt("Myri Diop", "borrowed", 30_000, 0) ])
    end

    private

    def render_row(debts)
      relation = DebtRelation.new(space: nil, name: debts.first.name, debts: debts)
      render_with_template(template: "shared/space_context", locals: { component: Debts::RelationRowComponent.new(relation: relation) })
    end

    def debt(name, direction, total, reimbursed)
      Debt.new(id: SecureRandom.uuid, name: name, direction: direction, total_lent: total, total_reimbursed: reimbursed)
    end
  end
end
