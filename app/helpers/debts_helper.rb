# frozen_string_literal: true

module DebtsHelper
  # First-day starters on the empty debts list: each opens the create sheet on the
  # right side.
  def debt_starters
    [
      { key: :lent, direction: "lent" },
      { key: :borrowed, direction: "borrowed" }
    ].map do |s|
      s.merge(label: t("debts.index.starters.#{s[:key]}.name"), hint: t("debts.index.starters.#{s[:key]}.hint"))
    end
  end

  # Repayment schedule surfaced from the budget line the debt feeds, or nil when
  # there's no dated plan. Turns the balance + deadline the app already knows into
  # "X per month · settled in <month> · N installments left" — no hand-typed note.
  def debt_schedule(debt)
    return unless debt.ongoing?

    line = debt.repayment_line
    return unless line&.ends_on && line.amount.to_f.positive?

    # Count the installments from what is still OWED, not from the calendar. The
    # monthly amount is fixed when the plan is made and nothing recomputes it
    # afterwards, so a month passing without a payment — or a partial repayment —
    # would otherwise leave a count that no longer adds up to the balance.
    monthly = line.amount.to_f
    installments = (debt.remaining_balance / monthly).ceil
    return if installments <= 0

    # Repayment starts next month: you don't pay the month you take the money on.
    start = Date.current.beginning_of_month.next_month
    { monthly: line.amount, ends_on: start >> (installments - 1),
      installments: installments, incoming: debt.lent? }
  end

  # Label for a closed debt in the history list: written-off (direction-aware) or settled.
  def debt_status_label(debt)
    if debt.written_off?
      t("debts.status.written_off.#{debt.direction}")
    else
      t("debts.status.settled")
    end
  end

  # The hero figure on a closed debt's page: the written-off amount (what won't
  # come back / no longer owed) for a write-off, the full amount for a settled one.
  def closed_debt_amount(debt)
    debt.written_off? ? debt.remaining_balance : debt.total_lent
  end

  def closed_debt_amount_label(debt)
    key = debt.written_off? ? debt.direction : "settled"
    t("debts.closed.amount_label.#{key}")
  end

  # Summary line for the collapsed closed section, e.g. "3 remboursées · 1 abandonnée".
  # Only the non-zero halves appear.
  def closed_debts_breakdown(debts)
    settled = debts.count(&:paid?)
    written_off = debts.count(&:written_off?)
    parts = []
    parts << t("debts.index.closed_settled_count", count: settled) if settled.positive?
    parts << t("debts.index.closed_written_off_count", count: written_off) if written_off.positive?
    parts.join(" · ")
  end

  # Row subtitle in the closed list: when it closed, and (for a write-off) that
  # you stopped counting on it.
  def closed_debt_row_subtitle(debt)
    date = l(debt.updated_at.to_date, format: :day_month)
    key = debt.written_off? ? "closed_written_off_on.#{debt.direction}" : "closed_settled_on"
    t("debts.index.#{key}", date: date)
  end

  # Short tag shown beside a written-off name in the closed list.
  def closed_debt_short_tag(debt)
    t("debts.index.closed_tag.#{debt.direction}")
  end

  # Small factual line under the hero, e.g. "15 000 récupéré sur 50 000". Only
  # shown when part of the debt had already moved before it closed.
  def closed_debt_detail(debt)
    return if debt.total_reimbursed.to_f.zero?

    t("debts.closed.detail.#{debt.direction}",
      moved: money(debt.total_reimbursed, current_space.currency),
      total: money(debt.total_lent, current_space.currency))
  end
end
