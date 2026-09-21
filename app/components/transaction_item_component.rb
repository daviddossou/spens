# frozen_string_literal: true

class TransactionItemComponent < ViewComponent::Base
  with_collection_parameter :transaction

  # context: :category renders the row inside its category's page — the label
  # becomes the title, the sub-category leads the subtitle (its absence stated
  # when the category has children), the type's emoji replaces the family icon,
  # and the nested fee is dropped so the list adds up to the page header.
  # link: false renders the same row as plain content (onboarding, where the
  # transaction's page is not reachable yet).
  def initialize(transaction:, context: :list, category: nil, subcategory_hint: false, show_date: false, link: true)
    @transaction = transaction
    @context = context
    @category = category
    @subcategory_hint = subcategory_hint
    @show_date = show_date
    @link = link
  end

  def wrapper(&block)
    return content_tag(:div, class: "transaction-item transaction-item--static", &block) unless @link

    link_to(helpers.transaction_path(locale: I18n.locale, id: transaction.id), class: "transaction-item",
            data: { turbo_frame: "_top" }, "aria-label": "#{title}: #{display_amount(row, transaction)}", &block)
  end

  private

  attr_reader :transaction, :context

  def in_category?
    context == :category
  end

  def title
    row.title
  end

  # In a category the subtitle may wrap, but never inside a part: each part
  # carries its own leading separator, so a break lands before « · account ».
  # A flat (ungrouped) list puts the date first.
  def subtitle
    return row.subtitle unless in_category?

    sub, account = row.in_category_subtitle_parts(@category&.id)
    sub ||= @subcategory_hint ? I18n.t("budgets.categories.show.no_subcategory") : nil
    date = @show_date ? I18n.l(transaction.transaction_date, format: :day_month_short) : nil
    parts = [ date, sub, account ].compact_blank
    spans = parts.each_with_index.map { |part, i| content_tag(:span, i.zero? ? part : "· #{part}", class: "transaction-item__part") }
    safe_join(spans, " ")
  end

  def emoji_icon
    in_category? ? row.type_emoji : nil
  end

  def show_fee?
    !in_category? && fee_row
  end

  # The row's meaning is composed by MovementRow: family, title, subtitle, and
  # how the amount reads. Subtitle amounts ("reste 45 000") are formatted without
  # a currency suffix to stay terse.
  def row
    @row ||= MovementRow.new(
      transaction,
      currency: currency,
      formatter: ->(amount) { helpers.money(amount.abs) }
    )
  end

  # A provider fee shown as a nested child line under its parent, never its own row.
  def fee_row
    return @fee_row if defined?(@fee_row)

    fee = transaction.fee
    @fee_row = fee && MovementRow.new(fee, currency: currency)
  end

  def currency
    @currency ||= transaction.space.currency
  end

  def icon_class
    emoji_icon ? "transaction-item__icon--emoji" : "transaction-item__icon--#{row.family}"
  end

  def icon_svg
    TransactionIconService.icon_svg_by_name(row.icon_name)
  end

  # Amounts stay dark where a balance really moved; neutral lines are muted.
  def amount_class
    row.muted? ? "transaction-item__amount--muted" : "transaction-item__amount--strong"
  end

  # Full amounts in the list (no "k"); the sign follows the row's rule.
  def display_amount(movement, transaction_for_amount)
    helpers.money(transaction_for_amount.amount, currency,
                  sign: movement.show_sign? ? :always : :none)
  end
end
