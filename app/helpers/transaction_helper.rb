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
end
