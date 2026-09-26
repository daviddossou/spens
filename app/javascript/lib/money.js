// Format a numeric amount as "1 234 Cur" using the given locale's grouping.
// Non-numbers fall back to 0. Locale may be blank (browser default).
export function formatMoney(value, currency, locale) {
  const amount = Number(value)
  const safe = Number.isFinite(amount) ? amount : 0
  return `${safe.toLocaleString(locale || undefined)} ${currency}`
}

// Parse an amount as typed: "12,50", "12.50", "1 250,50", "1.250,50", "1,250.50".
// Mirrors AmountInput on the server: a lone separator before exactly three digits
// groups thousands. Anything else that isn't a number gives NaN.
export function parseAmount(value) {
  let str = String(value ?? "").replace(/[\s']/g, "")
  if (str === "") return NaN

  const hasDot = str.includes("."), hasComma = str.includes(",")
  if (hasDot && hasComma) {
    const decimal = str.lastIndexOf(".") > str.lastIndexOf(",") ? "." : ","
    str = str.split(decimal === "." ? "," : ".").join("").replace(",", ".")
  } else if ((str.match(/[.,]/g) || []).length > 1 || /[.,]\d{3}$/.test(str)) {
    str = str.replace(/[.,]/g, "")
  } else {
    str = str.replace(",", ".")
  }
  return /^-?\d*\.?\d+$|^-?\d+\.$/.test(str) ? parseFloat(str) : NaN
}
