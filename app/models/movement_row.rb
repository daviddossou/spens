# frozen_string_literal: true

# Composes what a single movement shows in the list: its family (which drives the
# icon and colour), an app-built title, one subtitle line, and how the amount
# reads (sign + whether it's muted). The title is ALWAYS composed here from
# structured data — never copied from a free-text field — and the auto-description
# emojis are dropped, the family icon carrying the meaning instead (Tour 17c/d).
#
# Eight kinds read as five families: income → :income, expense → :expense,
# transfer_in/out → :transfer, debt_in/out → :debt, and the reconciliations
# (debt_writeoff, compensation, adjustment, initial_balance) → :neutral.
class MovementRow
  def initialize(transaction, currency: nil, locale: I18n.locale, formatter: nil)
    @txn = transaction
    @currency = currency || transaction.space&.currency
    @locale = locale
    @format = formatter || ->(amount) { amount.to_i.to_s }
  end

  def family
    return :neutral if TransactionKind.neutral?(kind)
    return :transfer if TransactionKind.transfer?(kind)
    return :debt if TransactionKind.debt?(kind)

    kind == "income" ? :income : :expense
  end

  # SVG basename for the family icon (see app/assets/images/<name>_icon.svg).
  def icon_name
    case kind
    when "compensation", "adjustment", "initial_balance" then "neutral"
    when "debt_writeoff" then "writeoff"
    when "transfer" then "transfer_in"
    else kind
    end
  end

  def title
    case kind
    when "transfer_out" then t("movement.transfer.out", account: partner_account_name)
    when "transfer_in"  then t("movement.transfer.in", account: partner_account_name)
    when "debt_in", "debt_out" then debt_title
    when "debt_writeoff" then t("movement.writeoff.#{debt_direction}", name: debt_name)
    when "compensation" then t("movement.compensation.title", name: debt_name)
    when "adjustment" then t("movement.adjustment.title", account: account_name)
    when "initial_balance" then t("movement.initial_balance.title", account: account_name)
    else labelled_title
    end
  end

  def subtitle
    case kind
    when "transfer_in", "transfer_out" then account_name
    when "debt_in", "debt_out" then debt_subtitle
    when "debt_writeoff" then t("movement.writeoff.#{debt_direction}_sub")
    when "compensation" then t("movement.compensation.sub")
    when "adjustment" then adjustment_subtitle
    when "initial_balance" then t("movement.initial_balance.sub")
    else category_subtitle
    end
  end

  # The SIGNED stored amount. Colour and sign are decided by muted?/show_sign?.
  def amount
    @txn.amount
  end

  # Neutral lines are muted (grey); everything where a balance really moved is dark.
  def muted?
    family == :neutral
  end

  # Show a +/- sign for real flows and for an adjustment (which states a delta);
  # the other neutral lines (compensation, write-off, initial balance) show none.
  def show_sign?
    return true unless family == :neutral

    kind == "adjustment"
  end

  # The sub-category the movement sits on (nil when it sits on the page's own
  # category) then the account.
  def in_category_subtitle_parts(page_category_id)
    type = @txn.transaction_type
    sub = type.id == page_category_id ? nil : clean(type.name)
    [ sub, account_name ]
  end

  # The type's own leading emoji, when it has one.
  def type_emoji
    @txn.transaction_type.name.to_s[/\A[^[:alnum:][:space:]]+/]&.strip.presence
  end

  # A fee is nested under its parent, never a top-level row of its own.
  def fee?
    @txn.fee_parent_id.present?
  end

  # Transfers are neutral space-wide but move a single account's balance.
  def counts_in_day_total?(scope: :space)
    return true if %w[income expense debt_in debt_out].include?(kind)

    scope == :account && TransactionKind.transfer?(kind)
  end

  # A day made only of opening balances carries "hors totaux", not a figure.
  def out_of_totals?
    kind == "initial_balance"
  end

  private

  def kind
    @kind ||= @txn.transaction_type.kind
  end

  def account_name
    @txn.account&.name
  end

  def partner_account_name
    @txn.transfer_partner&.account&.name || clean(@txn.transaction_type.name)
  end

  def debt_name
    @txn.debt&.name
  end

  def debt_direction
    @txn.debt&.direction || "lent"
  end

  # A loan/borrow (the debt grows) vs a repayment (it shrinks) — mirrors the
  # ledger's own increase test, so the phrase always matches the money.
  def debt_increase?
    (@txn.debt&.lent? && kind == "debt_out") || (@txn.debt&.borrowed? && kind == "debt_in")
  end

  def debt_title
    key = if debt_increase?
      @txn.debt&.lent? ? "loan" : "borrow"
    else
      @txn.debt&.lent? ? "repaid_in" : "repaid_out"
    end
    t("movement.debt.#{key}", name: debt_name)
  end

  def debt_subtitle
    return account_name if debt_increase?

    [ account_name, remaining_note ].compact.join(" · ")
  end

  def remaining_note
    remaining = @txn.debt&.remaining_balance.to_f
    return t("movement.debt.settled") if remaining <= 0

    t("movement.debt.remaining", amount: money(remaining))
  end

  def adjustment_subtitle
    key = amount.negative? ? "less" : "more"
    t("movement.adjustment.#{key}", amount: money(amount.abs))
  end

  # The user's own words lead: the extracted label, else the cleaned note ("L'indien",
  # "Carrefour Market"), and the category drops to the subtitle. Without either the
  # category IS the title, so the subtitle keeps only the parent — never repeating it.
  def labelled_title
    clean(label.presence || note_label.presence || @txn.transaction_type.name)
  end

  def label
    @txn.label
  end

  def category_subtitle
    own_words = label.present? || note_label.present?
    detail = own_words ? clean(@txn.transaction_type.name) : parent_category
    [ account_name, detail ].reject { |part| part.to_s.strip.empty? }.join(" · ")
  end

  # The cleaned note, unless it only repeats the category name.
  def note_label
    return @note_label if defined?(@note_label)

    cleaned = QuickEntry::NoteLabel.call(@txn.note, account_name: account_name)
    category = clean(@txn.transaction_type.name)
    repeats = cleaned.present? && CategoryText.normalize(cleaned) == CategoryText.normalize(category)
    @note_label = repeats ? nil : cleaned.presence
  end

  def parent_category
    clean(@txn.transaction_type.parent&.name)
  end

  def money(value)
    @format.call(value)
  end

  # Taxonomy/system names may carry a leading emoji; the family icon replaces it.
  def clean(name)
    name.to_s.sub(/\A[^[:alnum:]]+/, "").strip
  end

  def t(key, **args)
    I18n.t("transactions.#{key}", locale: @locale, **args)
  end
end
