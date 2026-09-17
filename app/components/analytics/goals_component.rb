# frozen_string_literal: true

class Analytics::GoalsComponent < ViewComponent::Base
  def initialize(goals:)
    @goals = goals
  end

  private

  attr_reader :goals

  delegate :money_pair, to: :helpers
end
