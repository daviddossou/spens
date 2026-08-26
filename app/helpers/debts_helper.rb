# frozen_string_literal: true

module DebtsHelper
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

  # Small factual line under the hero, e.g. "15 000 récupéré sur 50 000". Only
  # shown when part of the debt had already moved before it closed.
  def closed_debt_detail(debt)
    return if debt.total_reimbursed.to_f.zero?

    t("debts.closed.detail.#{debt.direction}",
      moved: smart_format_money(debt.total_reimbursed, current_space.currency, sign: :never),
      total: smart_format_money(debt.total_lent, current_space.currency, sign: :never))
  end
end
