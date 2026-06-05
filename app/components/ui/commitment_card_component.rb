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
                :accent, :progress_label, :complete_label, :remaining_label

    def initialize(title:, current_value:, target_value:, currency:, url: nil,
                   accent: "primary", progress_label: "done",
                   complete_label: "Complete", remaining_label: "left")
      @title = title
      @current_value = current_value.to_f
      @target_value = target_value.to_f
      @currency = currency
      @url = url
      @accent = accent
      @progress_label = progress_label
      @complete_label = complete_label
      @remaining_label = remaining_label
    end

    def percentage
      return 0 if target_value.zero?

      [ [ (current_value / target_value * 100).round, 100 ].min, 0 ].max
    end

    def remaining_value
      [ target_value - current_value, 0 ].max
    end

    def settled?
      target_value.positive? && current_value >= target_value
    end

    def root_class
      [ "commitment-card", "commitment-card--#{url.present? ? 'row' : 'summary'}",
        "commitment-card--accent-#{accent}" ].join(" ")
    end

    def formatted_remaining
      helpers.smart_format_money(remaining_value, currency)
    end

    def formatted_current_value
      helpers.smart_format_money(current_value, currency)
    end

    def formatted_target_value
      helpers.smart_format_money(target_value, currency)
    end

    def bar
      fill_class = [ "commitment-card__bar-fill", ("commitment-card__bar-fill--settled" if settled?) ].compact.join(" ")
      tag.div(
        tag.div("", class: fill_class, style: "width: #{percentage}%;"),
        class: "commitment-card__bar", role: "progressbar",
        "aria-valuenow": percentage, "aria-valuemin": 0, "aria-valuemax": 100
      )
    end

    # Compact two-sided caption for the row variant: "74% repaid · 629K / 855K".
    def meta
      tag.div(
        safe_join([
          tag.span("#{percentage}% #{progress_label}"),
          # safe_join keeps the html_safe spans smart_format_money returns for
          # abbreviated values, so they render instead of being escaped.
          tag.span(safe_join([ formatted_current_value, " / ", formatted_target_value ]))
        ]),
        class: "commitment-card__meta"
      )
    end

    # Natural-language progress for the summary variant: "629K repaid of 855K".
    def progress_summary
      safe_join([ formatted_current_value, " #{progress_label} of ", formatted_target_value ])
    end
  end
end
