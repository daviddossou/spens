// Format a numeric amount as "1 234 Cur" using the given locale's grouping.
// Non-numbers fall back to 0. Locale may be blank (browser default).
export function formatMoney(value, currency, locale) {
  const amount = Number(value)
  const safe = Number.isFinite(amount) ? amount : 0
  return `${safe.toLocaleString(locale || undefined)} ${currency}`
}
