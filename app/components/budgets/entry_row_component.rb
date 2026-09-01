# frozen_string_literal: true

module Budgets
  # One budget line for a month: name, planned vs actual (summed over every
  # matching transaction), a slim progress bar, and a fulfillment state derived
  # from the cumulative actual reaching the planned amount.
  class EntryRowComponent < ViewComponent::Base
    attr_reader :entry, :actual, :currency, :read_only, :mode

    def initialize(entry:, actual:, currency:, read_only: false, mode: :live)
      @entry = entry
      @actual = actual.to_f
      @currency = currency
      @read_only = read_only
      @mode = mode
    end

    # Plan mode is forward-looking: no actuals, bars or status — a line just
    # states what it plans to be. Showing 0 € realised would read as "behind".
    def plan_mode?
      mode == :plan
    end

    # Expense lines carry a Vital / Confort tag (essential or adjustable);
    # income, transfers and debts don't split that way.
    def essential_label
      return nil unless entry.kind == "expense"

      t("budgets.index.#{entry.budget_item&.essential ? 'vital_label' : 'confort_label'}")
    end

    # For a debt line, whether the money comes to you (a lent debt being repaid)
    # or you send it (repaying what you borrowed) — otherwise the two read alike.
    def debt_direction_label
      case entry.kind
      when "debt_in" then t("budgets.row.debt_to_receive")
      when "debt_out" then t("budgets.row.debt_to_repay")
      end
    end

    # A lent debt being repaid to you — the incoming side of the Dettes section,
    # coloured green to set it apart from the amounts you owe.
    def incoming_debt?
      entry.kind == "debt_in"
    end

    # This month's amount was set by hand and diverges from the rule.
    def exception?
      entry.overridden?
    end

    # On an exception line the frequency slot says what the rule usually plans,
    # so "chaque mois" gives way to "habituellement 120K". _html so the
    # abbreviated-money span survives interpolation.
    def usually_label
      t("budgets.row.usually_html", amount: helpers.money(entry.rule_amount, currency))
    end

    # Meta subline under the name: the Vital/Confort tag (expense) or the
    # receive/repay direction (debt), then the frequency — or "usually X" when
    # this month is an exception. safe_join keeps the money span intact.
    def meta_line
      cadence = exception? ? usually_label : frequency_label
      safe_join([ essential_label, debt_direction_label, cadence ].compact, " · ")
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

    # "Left" reads as money still to spend; incoming money is still to receive;
    # a debt I owe is money still to send.
    def left_label_key
      case entry.kind
      when "income", "debt_in" then "to_receive_html"
      when "debt_out" then "to_send_html"
      else "left_html"
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

    def carried
      entry.carried_amount.to_f
    end

    def carried?
      carried.positive?
    end

    def formatted_carried
      helpers.money(carried, currency)
    end

    def formatted_planned
      helpers.money(planned, currency)
    end

    def formatted_actual
      helpers.money(actual, currency)
    end

    def formatted_overage
      helpers.money(overage, currency)
    end

    def frequency_label
      freq = entry.budget_item&.frequency
      freq ? t("budgets.frequencies.#{freq}") : nil
    end
  end
end
