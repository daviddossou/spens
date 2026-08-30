# frozen_string_literal: true

class TransactionItemComponent < ViewComponent::Base
  with_collection_parameter :transaction

  def initialize(transaction:)
    @transaction = transaction
  end

  private

  attr_reader :transaction

  # The row's meaning is composed by MovementRow: family, title, subtitle, and
  # how the amount reads. Subtitle amounts ("reste 45 000") are formatted without
  # a currency suffix to stay terse.
  def row
    @row ||= MovementRow.new(
      transaction,
      currency: currency,
      formatter: ->(amount) { helpers.format_money_number(amount.abs) }
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
    "transaction-item__icon--#{row.family}"
  end

  def icon_svg
    TransactionIconService.icon_svg_by_name(row.icon_name)
  end

  # Amounts stay dark where a balance really moved; neutral lines are muted.
  def amount_class
    row.muted? ? "transaction-item__amount--muted" : "transaction-item__amount--strong"
  end

  # Full amounts in the list (no "K"); the sign follows the row's rule.
  def display_amount(movement, transaction_for_amount)
    helpers.smart_format_money(
      transaction_for_amount.amount,
      currency,
      sign: movement.show_sign? ? :always : :never,
      threshold: Float::INFINITY
    )
  end
end
