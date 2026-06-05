# frozen_string_literal: true

module AnalyticsHelper
  # Categorical palette for charts, anchored on the Spens brand colors so the
  # doughnuts/bars sit on-palette instead of using Chartkick's defaults.
  CHART_PALETTE = %w[
    #3F51B5
    #FF9800
    #4CAF50
    #2196F3
    #F44336
    #9C27B0
    #00ACC1
    #5C6BC0
    #FF7043
    #26A69A
  ].freeze

  def chart_palette
    CHART_PALETTE
  end

  # Semantic colors used by the trend lines.
  def chart_income_color = "#4CAF50"  # success
  def chart_expense_color = "#F44336" # danger
  def chart_primary_color = "#3F51B5" # primary
end
