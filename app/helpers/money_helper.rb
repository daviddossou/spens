module MoneyHelper
  # The single money formatter (Tour 28c): every displayed amount goes through
  # here so the whole app speaks one format. The currency is always attached
  # (non-breaking space); nil means "no data" and renders an em dash, while a
  # real zero says "0 FCFA".
  NBSP = "\u00A0"
  NNBSP = "\u202F" # espace fine insécable, before the k/M unit
  ABBREVIATE_AT = 10_000
  MILLION = 1_000_000

  # sign: :none (absolute, default), :auto ("−" on negatives), :always ("+"/"−").
  # compact: abbreviates from 10 000 up ("35 k", "1,2 M") — never below.
  def money(amount, currency_code = nil, compact: false, sign: :none)
    return "—" if amount.nil?

    currency_code ||= current_space&.currency || "XOF"
    abs = amount.abs.round(2)
    body = compact && abs >= ABBREVIATE_AT ? abbreviated_money(abs) : plain_money(abs)
    "#{money_sign(amount, sign)}#{body}#{NBSP}#{get_currency_symbol(currency_code)}"
  end

  # A column reads in ONE format, and its SMALLEST value decides (Tour 32d):
  # a single amount under the floor puts the whole column in exact, so adding a
  # small account never reformats the amounts above it. nil abstains.
  def money_column(amounts, currency_code = nil, compact: false)
    known = amounts.compact
    abbreviate = compact && known.any? && known.all? { |a| a.abs.round(2) >= ABBREVIATE_AT }
    amounts.map { |a| money(a, currency_code, compact: abbreviate) }
  end

  def money_pair(first, second, currency_code = nil, compact: false)
    money_column([ first, second ], currency_code, compact: compact)
  end

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

  private

  def money_sign(amount, sign)
    negative = amount.negative? && amount.abs.round(2).positive?
    case sign
    when :always
      amount.abs.round(2).zero? ? "" : (negative ? "−#{NBSP}" : "+#{NBSP}")
    when :auto
      negative ? "−#{NBSP}" : ""
    else
      ""
    end
  end

  # Whole amounts drop the trailing ".00"; cents keep 2 decimals.
  def plain_money(abs)
    if (abs % 1).zero?
      number_with_delimiter(abs.to_i)
    else
      number_with_precision(abs, precision: 2, delimiter: I18n.t("number.format.delimiter", default: ","))
    end
  end

  # "35 k", "145 k", "1,2 M" — a fine space keeps the number from reading as an
  # identifier ("35k"), lowercase k, at most 1 meaningful decimal.
  def abbreviated_money(abs)
    value, unit = abs >= MILLION ? [ abs / MILLION.to_f, "M" ] : [ abs / 1_000.0, "k" ]
    rounded = value.round(1)
    body = (rounded % 1).zero? ? number_with_delimiter(rounded.to_i) : number_with_precision(rounded, precision: 1)
    "#{body}#{NNBSP}#{unit}"
  end
end
