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
    if kind == "income"
      "transaction-item__icon--income"
    elsif kind.include?("debt")
      "transaction-item__icon--debt"
    elsif kind.include?("transfer")
      "transaction-item__icon--transfer"
    else
      "transaction-item__icon--expense"
    end
  end

  def icon_svg
    # Handle generic "transfer" by defaulting to "transfer_in"
    icon_kind = kind == "transfer" ? "transfer_in" : kind
    icon_path = Rails.root.join("app", "assets", "images", "#{icon_kind}_icon.svg")
    return "" unless File.exist?(icon_path)

    File.read(icon_path).html_safe
  end

  def amount_class
    if kind == "income"
      "transaction-item__amount--income"
    elsif kind == "expense"
      "transaction-item__amount--expense"
    else
      "transaction-item__amount--neutral"
    end
  end

  def amount_prefix
    %w[income debt_in transfer_in].include?(kind) ? "+" : "-"
  end
end
