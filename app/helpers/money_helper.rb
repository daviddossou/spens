module MoneyHelper
  # Format currency with proper symbol placement and formatting
  def format_money(amount, currency_code = nil)
    currency_code ||= current_space&.currency || "XOF"
    "#{format_money_number((amount || 0).abs.round(2))} #{get_currency_symbol(currency_code)}"
  end

  # Smart number formatting with abbreviations (K, M, B) and hover for full value
  # sign: :auto (default) shows '-' for negatives only
  # sign: :always shows '+' or '-'
  # sign: :never shows no sign
  def smart_format_money(amount, currency_code = nil, threshold: 1_000, sign: :auto)
    currency_code ||= current_space&.currency || "XOF"
    currency_symbol = get_currency_symbol(currency_code)
    abs_amount = (amount || 0).abs.round(2)
    negative = (amount || 0).negative? && abs_amount.positive?

    prefix = case sign
    when :always
      abs_amount.zero? ? "" : (negative ? "- " : "+ ")
    when :never
      ""
    else # :auto
      negative ? "-" : ""
    end

    # If below threshold, show full number
    if abs_amount < threshold
      return "#{prefix}#{format_money_number(abs_amount)} #{currency_symbol}"
    end

    # Calculate abbreviated value
    abbreviated, suffix = if abs_amount >= 1_000_000_000
      [ (abs_amount / 1_000_000_000.0).round(2), "B" ]
    elsif abs_amount >= 1_000_000
      [ (abs_amount / 1_000_000.0).round(2), "M" ]
    else
      [ (abs_amount / 1_000.0).round(2), "K" ]
    end

    # Abbreviated values stay terse: drop a trailing ".0" on whole multiples
    # (5K, not 5.0K) but keep meaningful decimals (2.21K).
    abbreviated_str = (abbreviated % 1).zero? ? abbreviated.to_i.to_s : abbreviated.to_s
    full_amount = format_money_number(abs_amount)

    content_tag :span,
                "#{prefix}#{abbreviated_str}#{suffix} #{currency_symbol}",
                title: "#{prefix}#{full_amount} #{currency_symbol}",
                class: "cursor-help",
                tabindex: "0",
                role: "button",
                "aria-label": "#{prefix}#{full_amount} #{currency_symbol}",
                data: { toggle: "tooltip" }
  end

  # Render a money magnitude with a thousands delimiter, showing 2 decimals
  # only when the value has cents — whole amounts drop the trailing ".00"
  # (60 -> "60", 218.37 -> "218.37", 0.5 -> "0.50", 2.21 -> "2.21").
  def format_money_number(abs_amount)
    if (abs_amount % 1).zero?
      number_with_delimiter(abs_amount.to_i)
    else
      number_with_precision(abs_amount, precision: 2,
                            delimiter: I18n.t("number.format.delimiter", default: ","),
                            separator: I18n.t("number.format.separator", default: "."))
    end
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
