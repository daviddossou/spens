module TransactionHelper
  # Get icon CSS class for transaction based on kind
  def transaction_icon_class(kind)
    TransactionIconService.icon_class(kind, scope: "transaction-show")
  end

  # Get header CSS class for transaction based on kind
  def transaction_header_class(kind)
    TransactionIconService.header_class(kind)
  end

  # Get amount CSS class for transaction based on kind
  def transaction_amount_class(kind)
    TransactionIconService.amount_class(kind, scope: "transaction-show")
  end

  # Get badge CSS class for transaction kind
  def transaction_badge_class(kind)
    TransactionIconService.badge_class(kind)
  end

  # Get icon SVG for transaction kind
  def transaction_icon_svg(kind)
    TransactionIconService.icon_svg(kind)
  end

  # Get amount prefix (+ or -)
  def transaction_amount_prefix(kind)
    TransactionIconService.amount_prefix(kind)
  end

  # Get signed amount based on transaction kind
  def transaction_signed_amount(transaction)
    kind = transaction.transaction_type.kind
    income_kinds = %w[income debt_in transfer_in]
    income_kinds.include?(kind) ? transaction.amount.abs : -transaction.amount.abs
  end

  # Top-level cards for the transaction picker. "Debt" is a UI category (not a
  # kind); it resolves to debt_in/debt_out once a person and intent are chosen.
  # Its default link target is the concrete kind "debt_out".
  def transaction_top_level_options(form)
    [
      { value: "expense",  kind: "expense",  label: t("transactions.form.kind_expense"),  selected: form.kind == "expense" },
      { value: "income",   kind: "income",   label: t("transactions.form.kind_income"),   selected: form.kind == "income" },
      { value: "transfer", kind: "transfer", label: t("transactions.form.kind_transfer"), selected: form.kind == "transfer" },
      { value: "debt",     kind: "debt_out", label: t("transactions.form.kind_debt"),     selected: form.debt_transaction? }
    ]
  end

  # The two intent cards for a given debt direction, rendered debt_in first to
  # match the debt-detail screens. Returns nil when direction is unknown.
  def debt_direction_intent_options(direction)
    return [] if direction.blank?

    [
      { kind: "debt_in",  label: t("transactions.form.kind_debt_in.#{direction}") },
      { kind: "debt_out", label: t("transactions.form.kind_debt_out.#{direction}") }
    ]
  end

  # Nested label map for the Stimulus controller so intent labels can be swapped
  # client-side when the direction changes (no server round-trip).
  def debt_intent_label_map
    %w[lent borrowed].index_with do |direction|
      {
        "debt_in"  => t("transactions.form.kind_debt_in.#{direction}"),
        "debt_out" => t("transactions.form.kind_debt_out.#{direction}")
      }
    end
  end
end
