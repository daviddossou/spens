# frozen_string_literal: true

class Analytics::DebtSummaryComponent < ViewComponent::Base
  def initialize(relations:)
    @relations = relations
  end

  private

  attr_reader :relations

  delegate :money, to: :helpers
end
