# frozen_string_literal: true

class Debts::RelationRowComponent < ViewComponent::Base
  def initialize(relation:)
    @relation = relation
  end

  private

  attr_reader :relation

  delegate :current_space, :money, to: :helpers
end
