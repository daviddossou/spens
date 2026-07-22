import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "spens:landing-country"

// Timezone → country code, for picking a sensible default without any API.
const TZ_MAP = {
  "Africa/Porto-Novo": "BJ",
  "Africa/Abidjan": "CI",
  "Africa/Dakar": "SN",
  "Africa/Lome": "TG",
  "Africa/Ouagadougou": "BF",
  "Africa/Bamako": "ML",
  "Africa/Niamey": "NE",
  "Africa/Conakry": "GN",
  "Africa/Douala": "CM",
  "Africa/Lagos": "NG",
  "Africa/Accra": "GH",
  "Europe/Paris": "FR",
}

// Display symbol per currency code (mirrors MoneyHelper#get_currency_symbol).
const SYMBOLS = { XOF: "FCFA", XAF: "FCFA", GNF: "FG", NGN: "₦", GHS: "GH₵", EUR: "€", USD: "$" }

// Rounded weekly example amount per currency (≈ 1 000 FCFA), for the copy.
const EXAMPLE_AMOUNTS = { XOF: 1000, XAF: 1000, GNF: 15000, NGN: 2500, GHS: 25, EUR: 2, USD: 2 }

// Country/currency picker: changes the currency label everywhere on the page.
// No conversion; entered amounts keep their value.
export default class extends Controller {
  static targets = ["button", "menu", "flag", "code"]
  static values = { countries: Array }

  connect() {
    this.outsideClick = (e) => {
      if (!this.element.contains(e.target)) this.close()
    }
    const country = this.apply(this.detectCountry())

    // A saved manual choice also restores its language (auto-detection alone
    // only sets the currency, so a direct /fr or /en visit is never overridden).
    const locale = country.lang.toLowerCase()
    if (this.savedCountry() && locale !== document.documentElement.lang) {
      window.location.href = `/${locale}/welcome`
    }
  }

  savedCountry() {
    try { return localStorage.getItem(STORAGE_KEY) } catch { return null }
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClick)
  }

  toggle() {
    this.menuTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.menuTarget.hidden = false
    document.addEventListener("click", this.outsideClick)
  }

  close() {
    this.menuTarget.hidden = true
    document.removeEventListener("click", this.outsideClick)
  }

  pick(event) {
    const code = event.currentTarget.dataset.code
    try { localStorage.setItem(STORAGE_KEY, code) } catch {}
    const country = this.apply(code)
    this.close()

    // The country's language drives the page locale.
    const locale = country.lang.toLowerCase()
    if (locale !== document.documentElement.lang) {
      window.location.href = `/${locale}/welcome`
    }
  }

  apply(code) {
    const country = this.countriesValue.find((c) => c.code === code) || this.countriesValue[0]
    this.flagTarget.textContent = country.flag
    this.codeTarget.textContent = country.cur
    document.querySelectorAll("[data-currency-label]").forEach((el) => {
      el.textContent = country.cur
    })
    document.querySelectorAll("[data-currency-symbol]").forEach((el) => {
      el.textContent = SYMBOLS[country.cur] || country.cur
    })
    const example = EXAMPLE_AMOUNTS[country.cur]
    if (example) {
      const locale = document.documentElement.lang === "en" ? "en" : "fr-FR"
      document.querySelectorAll("[data-example-amount]").forEach((el) => {
        el.textContent = example.toLocaleString(locale)
      })
    }
    document.querySelectorAll("[data-lang-label]").forEach((el) => {
      el.textContent = country.lang
    })
    return country
  }

  detectCountry() {
    const saved = this.savedCountry()
    if (saved && this.countriesValue.some((c) => c.code === saved)) return saved

    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone
    if (TZ_MAP[tz]) return TZ_MAP[tz]

    const region = (navigator.language || "").split("-")[1]?.toUpperCase()
    if (region && this.countriesValue.some((c) => c.code === region)) return region

    return "BJ"
  }
}
