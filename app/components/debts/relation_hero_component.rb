# frozen_string_literal: true

class Debts::RelationHeroComponent < ViewComponent::Base
  def initialize(debt:, relation:)
    @debt = debt
    @relation = relation
  end

  private

  attr_reader :debt, :relation

  delegate :money, to: :helpers
end
