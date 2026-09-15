# frozen_string_literal: true

module Budgets
  # How far a budget line is for one month: planned vs actual, the fulfillment
  # state and the words for it. Shared by the line row and the category detail
  # page so both read the same status word for word.
  class LineProgress
    attr_reader :entry, :actual

    def initialize(entry:, actual:)
      @entry = entry
      @actual = actual.to_f
    end

    def kind
      entry.kind
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

    # Only spending directions can be "over budget"; incoming money and
    # transfers above plan are fine or neutral.
    def spending_kind?
      %w[expense debt_out].include?(kind)
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

    def remaining
      planned - actual
    end

    def incoming?
      %w[income debt_in].include?(kind)
    end

    def status_label
      if fulfilled?
        I18n.t("budgets.row.done_#{kind}")
      elsif actual.positive?
        I18n.t("budgets.row.in_progress")
      else
        I18n.t("budgets.row.expected")
      end
    end

    # "Left" reads as money still to spend; incoming money is still to receive;
    # a debt I owe is money still to send.
    def left_label_key
      case kind
      when "income", "debt_in" then "to_receive_html"
      when "debt_out" then "to_send_html"
      else "left_html"
      end
    end

    def bar_class
      [ "budget-row__bar-fill",
        ("budget-row__bar-fill--over" if over?),
        ("budget-row__bar-fill--income" if incoming?),
        ("budget-row__bar-fill--transfer" if kind == "transfer") ].compact.join(" ")
    end
  end
end
