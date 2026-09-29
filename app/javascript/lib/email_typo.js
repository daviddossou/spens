// Suggests a fix for a mistyped e-mail domain ("gmial.com" → "gmail.com"). Only nudges
// towards well-known providers, never rejects: an unknown domain may simply be real.
const PROVIDERS = [
  "gmail.com", "yahoo.com", "yahoo.fr", "hotmail.com", "hotmail.fr", "outlook.com", "outlook.fr",
  "icloud.com", "live.com", "live.fr", "orange.fr", "free.fr", "laposte.net", "proton.me", "protonmail.com"
]

// Distance 1 catches one slip; 2 is allowed only on longer domains so "live.fr" doesn't pull "free.fr".
const tolerance = (domain) => (domain.length >= 9 ? 2 : 1)

export function suggestEmail(email, providers = PROVIDERS) {
  const value = String(email || "").trim().toLowerCase()
  const at = value.lastIndexOf("@")
  if (at < 1 || at === value.length - 1) return null

  const local = value.slice(0, at)
  const domain = value.slice(at + 1)
  if (providers.includes(domain)) return null

  let best = null
  for (const provider of providers) {
    const distance = levenshtein(domain, provider)
    if (distance <= tolerance(provider) && (best === null || distance < best.distance)) {
      best = { provider, distance }
    }
  }
  return best ? `${local}@${best.provider}` : null
}

export function levenshtein(a, b) {
  const rows = a.length + 1
  const cols = b.length + 1
  let previous = Array.from({ length: cols }, (_, j) => j)
  for (let i = 1; i < rows; i++) {
    const current = [i]
    for (let j = 1; j < cols; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1
      current[j] = Math.min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
    }
    previous = current
  }
  return previous[cols - 1]
}
