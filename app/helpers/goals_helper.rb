# frozen_string_literal: true

module GoalsHelper
  # A list amount in the app's money format: currency always shown, abbreviated
  # from five digits up (40k FCFA, 500k FCFA).
  def goal_money(value)
    money(value, current_space.currency, compact: true)
  end

  # First-day starters on the empty goals list: a tap opens the create sheet with
  # the name prefilled (or blank, for "something else"). Labels are localized.
  def goal_starters
    %i[cushion trip other].map do |key|
      name = t("goals.starters.#{key}.name")
      { key: key, name: (key == :other ? nil : name), label: name, hint: t("goals.starters.#{key}.hint") }
    end
  end

  # "30k FCFA par mois jusqu'en août 2027" with a deadline, "À ton rythme, sans
  # date" without one. The pace rounds to a clean thousand once it abbreviates.
  def goal_rhythm_text(progress)
    return t("goals.rhythm.no_deadline") unless progress.monthly

    amount = progress.monthly >= MoneyHelper::ABBREVIATE_AT ? (progress.monthly / 1000.0).round * 1000 : progress.monthly.round
    t("goals.rhythm.on_pace_html", amount: goal_money(amount), month: l(progress.deadline, format: :month_year))
  end

  # A tinted status pill for the list (reached / on track / behind), or nil when
  # there's nothing to pace against.
  def goal_status_chip(progress)
    label, modifier = goal_status_parts(progress)
    return unless label

    tag.span(label, class: "goal-chip goal-chip--#{modifier}")
  end

  # The detail hero's summary line: "Il reste 355 000 · 12 mois · Dans les temps".
  def goal_hero_meta(progress)
    return goal_status_chip(progress) if progress.settled?

    parts = []
    if progress.remaining.positive?
      parts << t("goals.hero.remaining",
                 amount: money(progress.remaining, current_space.currency))
      parts << t("goals.hero.months_left", count: progress.months_left) if progress.months_left
    end
    if (chip = goal_status_chip(progress))
      parts << chip
    elsif progress.target_set?
      parts << "#{progress.percentage}%"
    end
    safe_join(parts, " · ")
  end

  private

  def goal_status_parts(progress)
    case progress.status
    when :reached then [ t("goals.status.reached"), "reached" ]
    when :on_track then [ t("goals.status.on_track"), "on-track" ]
    when :behind then [ t("goals.status.behind"), "behind" ]
    end
  end
end
