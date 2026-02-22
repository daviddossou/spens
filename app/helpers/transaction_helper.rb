module TransactionHelper
  # Get icon CSS class for transaction based on kind
  def transaction_icon_class(kind)
    if kind == "income"
      "transaction-show__icon--income"
    elsif kind.include?("debt")
      "transaction-show__icon--debt"
    elsif kind.include?("transfer")
      "transaction-show__icon--transfer"
    else
      "transaction-show__icon--expense"
    end
  end

  # Get header CSS class for transaction based on kind
  def transaction_header_class(kind)
    if kind == "income"
      "transaction-show__header--income"
    elsif kind == "expense"
      "transaction-show__header--expense"
    else
      "transaction-show__header--neutral"
    end
  end

  # Get amount CSS class for transaction based on kind
  def transaction_amount_class(kind)
    if kind == "income"
      "transaction-show__amount--income"
    elsif kind == "expense"
      "transaction-show__amount--expense"
    else
      "transaction-show__amount--neutral"
    end
  end

  # Get badge CSS class for transaction kind
  def transaction_badge_class(kind)
    if kind == "income"
      "transaction-show__badge--income"
    elsif kind.include?("debt")
      "transaction-show__badge--debt"
    elsif kind.include?("transfer")
      "transaction-show__badge--transfer"
    else
      "transaction-show__badge--expense"
    end
  end

  # Get icon SVG for transaction kind
  def transaction_icon_svg(kind)
    # Handle generic "transfer" by defaulting to "transfer_in"
    icon_kind = kind == "transfer" ? "transfer_in" : kind
    icon_path = Rails.root.join("app", "assets", "images", "#{icon_kind}_icon.svg")
    return "" unless File.exist?(icon_path)

    File.read(icon_path).html_safe
  end

  # Get amount prefix (+ or -)
  def transaction_amount_prefix(kind)
    %w[income debt_in transfer_in].include?(kind) ? "+" : "-"
  end
end
