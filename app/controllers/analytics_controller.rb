# frozen_string_literal: true

# Analyses answers "what changed?" — Budget owns "how much do I plan?".
class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index
    @period = Analyses::Period.new(params[:range],
                                   start_date: params[:start_date], end_date: params[:end_date])
    @spending = Analyses::SpendingQuery.new(space: current_space, period: @period)
  end
end
