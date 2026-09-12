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
    TransactionKind.money_in?(kind) ? transaction.amount.abs : -transaction.amount.abs
  end

  # Day-block header total; transfers count only in the :account scope.
  def movement_day_total(transactions, currency = nil, scope: :space)
    currency ||= current_space&.currency
    contributes = ->(txn) { MovementRow.new(txn).counts_in_day_total?(scope: scope) || txn.fee }

    if transactions.none?(&contributes) && transactions.any? { |t| MovementRow.new(t).out_of_totals? }
      return content_tag(:span, t("transactions.movement.day.out_of_totals"),
                         class: "transaction-group__total transaction-group__total--muted")
    end

    total = transactions.sum do |txn|
      counted = MovementRow.new(txn).counts_in_day_total?(scope: scope) ? txn.amount : 0
      counted + (txn.fee&.amount || 0)
    end

    content_tag(:span, money(total, currency, sign: :always),
                class: "transaction-group__total")
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

  # Where a kind-selector card points: a fresh new-transaction form for create,
  # or the same transaction's edit form (with the target kind) when editing.
  # kind-switch JS appends the live field values to the href before navigating.
  # The sheet's heading follows the kind ("What did you buy?" / "New expense · 11 Sept").
  def transaction_form_heading(form, person_locked: false, relation: nil)
    title_key = form.debt_transaction? ? (form.debt_id.present? ? "from_debt" : "debt") : form.kind
    type_key = form.kind == "transfer" ? "transfer" : (form.debt_transaction? ? "debt" : (form.kind == "income" ? "income" : "expense"))
    subtitle =
      if person_locked && relation
        net = relation.net
        balance = net > 0 ? t("transactions.new.person_you_owe", amount: money(net)) \
                : net < 0 ? t("transactions.new.person_they_owe", amount: money(-net)) \
                : t("transactions.new.person_settled")
        t("transactions.new.person_subtitle", name: relation.name, balance: balance)
      else
        t("transactions.new.new_subtitle_html", type: t("transactions.new.new_type_#{type_key}"),
                                                 date: l(form.transaction_date || Date.current, format: "%-d %B"))
      end
    { title: t("transactions.new.subtitle.#{title_key}"), subtitle: subtitle }
  end

  def transaction_kind_switch_path(form, target_kind)
    switch_params = form.kind_params(target_kind)
    if form.editing?
      # Pass id: as a keyword — a positional arg would be assigned to the
      # optional (:locale) scope segment instead of :id, producing a bad URL.
      edit_transaction_path(id: form.transaction.id, **switch_params)
    else
      new_transaction_path(switch_params)
    end
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
