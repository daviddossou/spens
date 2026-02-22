module MoneyHelper
  # Format currency with proper symbol placement and formatting
  def format_money(amount, currency_code = nil)
    return "0" if amount.nil? || amount.zero?

    currency_code ||= current_user&.currency || "XOF"
    formatted_number = number_with_delimiter(amount.abs.round(2), delimiter: ",", precision: 0)
    currency_symbol = get_currency_symbol(currency_code)

    "#{formatted_number} #{currency_symbol}"
  end

  # Smart number formatting with abbreviations (K, M, B) and hover for full value
  def smart_format_money(amount, currency_code = nil, threshold: 1_000)
    return format_money(0, currency_code) if amount.nil? || amount.zero?

    currency_code ||= current_user&.currency || "XOF"
    abs_amount = amount.abs.round(2)
    currency_symbol = get_currency_symbol(currency_code)

    # If below threshold, show full number
    if abs_amount < threshold
      formatted = number_with_delimiter(abs_amount, delimiter: ",", precision: 0)
      return "#{formatted} #{currency_symbol}"
    end

    # Calculate abbreviated value
    abbreviated, suffix = if abs_amount >= 1_000_000_000
      [(abs_amount / 1_000_000_000.0).round(1), "B"]
    elsif abs_amount >= 1_000_000
      [(abs_amount / 1_000_000.0).round(1), "M"]
    else
      [(abs_amount / 1_000.0).round(1), "K"]
    end

    # Format abbreviated number (remove .0 if whole number)
    abbreviated_str = abbreviated % 1 == 0 ? abbreviated.to_i.to_s : abbreviated.to_s
    full_amount = number_with_delimiter(abs_amount, delimiter: ",", precision: 0)

    content_tag :span,
                "#{abbreviated_str}#{suffix} #{currency_symbol}",
                title: "#{full_amount} #{currency_symbol}",
                class: "cursor-help",
                tabindex: "0",
                role: "button",
                "aria-label": "#{full_amount} #{currency_symbol}",
                data: { toggle: "tooltip" }
  end

  # Get currency symbol or code for display
  def get_currency_symbol(currency_code)
    case currency_code
    when "XOF", "XAF"
      "FCFA"
    when "EUR"
      "€"
    when "USD"
      "$"
    when "GBP"
      "£"
    else
      currency_code
    end
  end
end
