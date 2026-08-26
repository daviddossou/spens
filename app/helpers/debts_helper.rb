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
end
