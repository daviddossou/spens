# frozen_string_literal: true

module Debts
  # @label Relation Hero
  class RelationHeroComponentPreview < ViewComponent::Preview
    # Net in your favour
    def they_owe_more
      render_hero(lent: 100_000, borrowed: 30_000)
    end

    # Net against you
    def you_owe_more
      render_hero(lent: 10_000, borrowed: 30_000)
    end

    private

    def render_hero(lent:, borrowed:)
      lent_debt = Debt.new(id: SecureRandom.uuid, name: "Myri", direction: "lent", total_lent: lent)
      borrowed_debt = Debt.new(id: SecureRandom.uuid, name: "Myri", direction: "borrowed", total_lent: borrowed)
      relation = DebtRelation.new(space: nil, name: "Myri", debts: [ lent_debt, borrowed_debt ])
      component = Debts::RelationHeroComponent.new(debt: relation.primary_debt, relation: relation)
      render_with_template(template: "shared/space_context", locals: { component: component })
    end
  end
end
