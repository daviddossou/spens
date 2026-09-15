# frozen_string_literal: true

module Budgets
  # One category's month: every movement the budget counts for it (its own and
  # its sub-categories', fees excluded) so the list adds up to the amount the
  # Budget page shows. The page belongs to the category; a budget line, when
  # one exists for the month, only overlays the header.
  class CategoriesController < ApplicationController
    before_action :authenticate_user!

    def show
      @category = current_space.transaction_types.where(kind: %w[income expense]).find(params[:id])
      @month = parse_month(params[:month]) || Date.current.beginning_of_month
      @editable = @month >= Date.current.beginning_of_month
      @has_children = @category.children.exists?

      @transactions = month_movements(@month)
                      .includes(:transaction_type, :account)
                      .order(transaction_date: :desc, created_at: :desc)
                      .to_a
      @grouped = @transactions.group_by(&:transaction_date)
      @total = @transactions.sum(&:amount).abs.round(2)

      Budgets::EnsureEntriesService.new(space: current_space, month: @month).call
      @entry = entry_for(@category)
      @progress = @entry && Budgets::LineProgress.new(entry: @entry, actual: @total)
      # A child under a budgeted parent: it counts there, so say so.
      @parent_entry = @entry.nil? && @category.parent && entry_for(@category.parent)
      @parent_progress = @parent_entry && Budgets::LineProgress.new(entry: @parent_entry, actual: parent_actual)

      @average = three_month_average
      @usual_day = usual_day if @entry && @transactions.empty?
      # No envelope anywhere: nothing to pace against, the list reads flat with dates.
      @flat_list = @entry.nil? && !@parent_entry
    end

    private

    def month_movements(month)
      current_space.transactions.where(transaction_date: month.all_month, fee_parent_id: nil,
                                       transaction_type_id: @category.subtree_ids)
    end

    def entry_for(type)
      current_space.budget_entries.for_month(@month).joins(:budget_item)
                   .includes(:budget_item).find_by(budget_items: { transaction_type_id: type.id })
    end

    def parent_actual
      Budgets::ActualsQuery.new(space: current_space, month: @month).for_entry(@parent_entry)
    end

    # Mean of the three previous months, so the month reads against its own habit.
    def three_month_average
      sums = (1..3).map { |i| month_movements(@month << i).sum(:amount).abs }
      (sums.sum / 3).round
    end

    # A regular charge (insurance, rent) lands about the same day each month: when
    # each of the three previous months moved within a few days of one another, the
    # empty month can say which day to expect. Irregular spend yields nothing.
    def usual_day
      days = (1..3).map do |i|
        dates = month_movements(@month << i).pluck(:transaction_date).map(&:day).sort
        return nil if dates.empty?

        dates[dates.size / 2]
      end
      return nil if days.max - days.min > 3

      (days.sum / 3.0).round
    end
  end
end
