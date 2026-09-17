# frozen_string_literal: true

class Budgets::SummaryComponent < ViewComponent::Base
  def initialize(actual_net:, committed_to_goals:, free_value:, hero_value:, mode:, offplan_net:, planned_expense:, planned_income:, projected_net:)
    @actual_net = actual_net
    @committed_to_goals = committed_to_goals
    @free_value = free_value
    @hero_value = hero_value
    @mode = mode
    @offplan_net = offplan_net
    @planned_expense = planned_expense
    @planned_income = planned_income
    @projected_net = projected_net
  end

  private

  attr_reader :actual_net, :committed_to_goals, :free_value, :hero_value, :mode, :offplan_net, :planned_expense, :planned_income, :projected_net

  delegate :money, to: :helpers
end
