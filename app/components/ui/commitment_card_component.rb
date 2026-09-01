# frozen_string_literal: true

module Ui
  # A compact progress card shared by debts and goals. Shows the remaining
  # amount as the hero, a slim accent-colored progress bar, and a
  # "X% <progress> · current / target" caption.
  #
  # - url present  -> a clickable compact row (list views)
  # - url blank    -> a larger summary block (detail views)
  #
  # accent picks the bar color: "warning" (debts), "primary" (goals), "success".
  # Labels are passed in already localized by the caller.
  class CommitmentCardComponent < ViewComponent::Base
    attr_reader :title, :current_value, :target_value, :currency, :url,
                :accent, :progress_label, :complete_label, :remaining_label, :no_target_label

    def initialize(title:, current_value:, target_value:, currency:, url: nil,
                   accent: "primary", progress_label: "done",
                   complete_label: "Complete", remaining_label: "left", no_target_label: nil,
                   partial_bar_only: false)
      @title = title
      @current_value = current_value.to_f
      @target_value = target_value.to_f
      @currency = currency
      @url = url
      @accent = accent
      @progress_label = progress_label
      @complete_label = complete_label
      @remaining_label = remaining_label
      @no_target_label = no_target_label
      # When true, the bar shows only for a partially-settled commitment — an
      # empty bar at 0% reads calmer than the exposure it represents (a loan with
      # nothing repaid), so debts drop it and lean on the amount instead.
      @partial_bar_only = partial_bar_only
    end

    # No target yet: the card shows the current amount, not progress toward a goal.
    def target_set?
      target_value.positive?
    end

    def percentage
      return 0 if target_value.zero?

      [ [ (current_value / target_value * 100).round, 100 ].min, 0 ].max
    end

    def remaining_value
      [ target_value - current_value, 0 ].max
    end

    def settled?
      # Treat as settled once the remaining rounds to zero at currency precision,
      # so sub-cent float drift (e.g. reimbursed 0.004 short of lent) still reads
      # as "Soldé" instead of "0.0 € restant".
      target_value.positive? && remaining_value.round(2).zero?
    end

    def show_bar?
      return true unless @partial_bar_only

      percentage.positive? && !settled?
    end

    def root_class
      [ "commitment-card", "commitment-card--#{url.present? ? 'row' : 'summary'}",
        "commitment-card--accent-#{accent}" ].join(" ")
    end

    def formatted_remaining
      helpers.money(remaining_value, currency, compact: true)
    end

    # The pair reads in one format — the larger side decides.
    def formatted_current_value
      formatted_pair.first
    end

    def formatted_target_value
      formatted_pair.last
    end

    def formatted_pair
      @formatted_pair ||= helpers.money_pair(current_value, target_value, currency, compact: true)
    end

    def bar
      fill_class = [ "commitment-card__bar-fill", ("commitment-card__bar-fill--settled" if settled?) ].compact.join(" ")
      tag.div(
        tag.div("", class: fill_class, style: "width: #{percentage}%;"),
        class: "commitment-card__bar", role: "progressbar",
        "aria-valuenow": percentage, "aria-valuemin": 0, "aria-valuemax": 100
      )
    end

    # Compact two-sided caption for the row variant: "74% repaid · 629k / 855k".
    def meta
      tag.div(
        safe_join([
          tag.span("#{percentage}% #{progress_label}"),
          tag.span("#{formatted_current_value} / #{formatted_target_value}")
        ]),
        class: "commitment-card__meta"
      )
    end

    # Natural-language progress for the summary variant: "629k repaid of 855k".
    def progress_summary
      connector = I18n.t("commitment.of", default: "of")
      safe_join([ formatted_current_value, " #{progress_label} #{connector} ", formatted_target_value ])
    end
  end
end
