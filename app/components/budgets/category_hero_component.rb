# frozen_string_literal: true

class Budgets::CategoryHeroComponent < ViewComponent::Base
  def initialize(average:, category:, editable:, entry:, parent_progress:, progress:, total:, transactions:, usual_day:, income:, month_slug:, child_progresses: [])
    @child_progresses = child_progresses
    @average = average
    @category = category
    @editable = editable
    @entry = entry
    @parent_progress = parent_progress
    @progress = progress
    @total = total
    @transactions = transactions
    @usual_day = usual_day
    @month_slug = month_slug
    @income = income
  end

  private

  attr_reader :child_progresses, :month_slug, :average, :category, :editable, :entry, :parent_progress, :progress, :total, :transactions, :usual_day, :income

  delegate :money, to: :helpers
end
