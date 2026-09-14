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

    def progress
      @progress ||= Budgets::LineProgress.new(entry: entry, actual: actual)
    end

    delegate :planned, :percentage, :bar_percentage, :fulfilled?, :over?, :celebrate?,
             :overage, :status_label, :left_label_key, :bar_class, to: :progress

    # Income and expense lines open the category detail page (what the month's
    # amount is made of); the plan reading and the other kinds keep the edit sheet.
    def detail_path
      return nil if plan_mode? || entry.transaction_type_id.blank?

      helpers.category_budgets_path(id: entry.transaction_type_id, month: entry.month.strftime("%Y-%m"))
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
