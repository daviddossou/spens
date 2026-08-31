# frozen_string_literal: true

# Analyses answers "what changed?" — Budget owns "how much do I plan?".
class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index
    @period = Analyses::Period.new(params[:range],
                                   start_date: params[:start_date], end_date: params[:end_date])
    @spending = Analyses::SpendingQuery.new(space: current_space, period: @period)
    @rhythm = Analyses::RhythmQuery.new(space: current_space, period: @period)
    @relations = DebtRelation.all_ongoing(current_space).select { |r| r.owed_to_me.positive? || r.i_owe.positive? }
    @set_aside = Analyses::SetAsideQuery.new(space: current_space)
    @goals = current_space.goals.includes(:account).map { |g| GoalProgress.new(g) }
    @accounts = current_space.accounts.active.where("balance > 0").order(balance: :desc)
  end
end
