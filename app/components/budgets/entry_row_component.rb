# frozen_string_literal: true

module Budgets
  # One budget line for a month: name, planned vs actual (summed over every
  # matching transaction), a slim progress bar, and a fulfillment state derived
  # from the cumulative actual reaching the planned amount.
  class EntryRowComponent < ViewComponent::Base
    attr_reader :entry, :actual, :currency, :read_only

    def initialize(entry:, actual:, currency:, read_only: false)
      @entry = entry
      @actual = actual.to_f
      @currency = currency
      @read_only = read_only
    end

    def planned
      entry.planned_amount.to_f
    end

    def percentage
      return 0 if planned.zero?

      ((actual / planned) * 100).round
    end

    def bar_percentage
      [ percentage, 100 ].min
    end

    def fulfilled?
      actual >= planned
    end

    def over?
      spending_kind? && actual > planned
    end

    # An overspent line must not celebrate: the green check is reserved for
    # fulfilled-and-on-plan.
    def celebrate?
      fulfilled? && !over?
    end

    def overage
      actual - planned
    end

    # Only spending directions can be "over budget"; incoming money and
    # transfers above plan are fine or neutral.
    def spending_kind?
      %w[expense debt_out].include?(entry.kind)
    end

    def status_label
      if fulfilled?
        t("budgets.row.done_#{entry.kind}")
      elsif actual.positive?
        t("budgets.row.in_progress")
      else
        t("budgets.row.expected")
      end
    end

    def bar_class
      [ "budget-row__bar-fill",
        ("budget-row__bar-fill--over" if over?),
        ("budget-row__bar-fill--income" if %w[income debt_in].include?(entry.kind)),
        ("budget-row__bar-fill--transfer" if entry.kind == "transfer") ].compact.join(" ")
    end

    # Categories carry their own emoji in the name; transfer and debt lines get
    # a leading line-art icon so every row leads with a visual anchor.
    def leading_icon_kind
      case entry.kind
      when "transfer" then "transfer"
      when "debt_in", "debt_out" then "debt"
      end
    end

    def formatted_planned
      helpers.smart_format_money(planned, currency)
    end

    def formatted_actual
      helpers.smart_format_money(actual, currency)
    end

    def formatted_overage
      helpers.smart_format_money(overage, currency)
    end

    def frequency_label
      freq = entry.budget_item&.frequency
      freq ? t("budgets.frequencies.#{freq}") : nil
    end
  end
end
