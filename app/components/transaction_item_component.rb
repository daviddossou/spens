# frozen_string_literal: true

class TransactionItemComponent < ViewComponent::Base
  with_collection_parameter :transaction

  def initialize(transaction:)
    @transaction = transaction
  end

  private

  attr_reader :transaction

  def kind
    @kind ||= transaction.transaction_type.kind
  end

  def icon_class
    TransactionIconService.icon_class(kind)
  end

  def icon_svg
    TransactionIconService.icon_svg(kind)
  end

  def amount_class
    TransactionIconService.amount_class(kind)
  end

  def amount_prefix
    TransactionIconService.amount_prefix(kind)
  end
end
