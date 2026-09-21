// Display symbol per currency code (mirrors MoneyHelper#get_currency_symbol).
export const CURRENCY_SYMBOLS = { XOF: "FCFA", XAF: "FCFA", GNF: "FG", NGN: "₦", GHS: "GH₵", EUR: "€", USD: "$" }

export function currencySymbol(code) {
  return CURRENCY_SYMBOLS[code] || code
}
