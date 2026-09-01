import { Controller } from "@hotwired/stimulus"

// The choice layer: one shell, reused by every picker. It slides over the sheet
// and never navigates, so the form underneath keeps its amount and its fields
// (Tour 32c). A tap on a row chooses and returns — there is no validation step.
export default class extends Controller {
  static targets = ["root", "title", "step", "search", "context", "list"]
  static values = { createLabel: String, empty: String, planned: String, rest: String }

  connect() {
    this._onPop = this._onPop.bind(this)
    this._onKeydown = this._onKeydown.bind(this)
  }

  present(request) {
    this.request = request
    this.titleTarget.textContent = request.title || ""
    this.stepTarget.textContent = request.step || ""
    this.searchTarget.value = ""
    this.renderContext(request)
    this.renderRows("")

    if (!this.isOpen) this.show()
    this.listTarget.scrollTop = 0
  }

  show() {
    this.rootTarget.hidden = false
    // Two frames: the browser needs the element laid out before it will animate.
    requestAnimationFrame(() => requestAnimationFrame(() => this.rootTarget.classList.add("picker-layer--open")))
    document.body.classList.add("picker-layer-open")
    // The Android back gesture must close the layer, not the whole sheet.
    history.pushState({ pickerLayer: true }, "")
    window.addEventListener("popstate", this._onPop)
    document.addEventListener("keydown", this._onKeydown)
    this.isOpen = true
  }

  close() {
    if (!this.isOpen) return
    this.isOpen = false
    this.rootTarget.classList.remove("picker-layer--open")
    document.body.classList.remove("picker-layer-open")
    window.removeEventListener("popstate", this._onPop)
    document.removeEventListener("keydown", this._onKeydown)
    setTimeout(() => { if (!this.isOpen) this.rootTarget.hidden = true }, 200)
  }

  // The chevron, Escape and the Android gesture all step back by exactly one:
  // to the previous step of a two-step pick, otherwise to the sheet.
  back() {
    const previous = this.request?.onContextAction?.()
    if (previous) return this.present(previous)
    if (history.state?.pickerLayer) history.back(); else this.close()
  }

  filter() {
    this.renderRows(this.searchTarget.value.trim())
  }

  renderContext(request) {
    const ctx = request.context
    this.contextTarget.hidden = !ctx
    if (!ctx) return

    this.contextTarget.replaceChildren(
      this.el("span", "picker-layer__context-label", ctx.label),
      this.el("span", "picker-layer__context-value", ctx.value)
    )
    if (ctx.action) {
      const button = this.el("button", "picker-layer__context-action", ctx.action)
      button.type = "button"
      button.addEventListener("click", () => this.back())
      this.contextTarget.appendChild(button)
    }
  }

  renderRows(query) {
    const q = query.toLowerCase()
    // The promise of a layer is that typing brings the right row to line 1, so
    // a name that starts with the query outranks one that merely contains it,
    // which outranks a row matched only on a hidden alias.
    const rank = (row) => {
      const label = row.label.toLowerCase()
      if (label.startsWith(q)) return 0
      if (label.includes(q)) return 1
      if ((row.aliases || "").toLowerCase().includes(q)) return 2
      return 3
    }

    const rows = (this.request.rows || [])
      .map((row) => [ row, q ? rank(row) : 0 ])
      .filter(([ , r ]) => r < 3)
      .sort((a, b) => a[1] - b[1])
      .map(([ row ]) => row)
    const list = document.createDocumentFragment()

    // "Aucun" is a legitimate answer, so it leads the list — never a hidden
    // renunciation at the bottom. It has nothing to match, so search hides it.
    if (this.request.emptyLabel && !q) {
      list.appendChild(this.rowNode({ value: "", label: this.request.emptyLabel }, { none: true }))
    }

    if (rows.length === 0 && !this.request.allowCreate) {
      list.appendChild(this.el("li", "picker-layer__empty", this.emptyValue))
    } else if (this.request.grouped && !q) {
      for (const [group, heading] of [["planned", this.plannedValue], ["rest", this.restValue]]) {
        const inGroup = rows.filter((r) => r.group === group)
        if (inGroup.length === 0) continue
        // One lone group is just the list — a heading over everything says nothing.
        if (rows.some((r) => r.group !== group)) list.appendChild(this.el("li", "picker-layer__group", heading))
        inGroup.forEach((row) => list.appendChild(this.rowNode(row)))
      }
    } else {
      rows.forEach((row) => list.appendChild(this.rowNode(row)))
    }

    // "Créer" always sits last, so it is visible without ever being in the way.
    if (this.request.allowCreate && !this.hasExactMatch(rows, query)) {
      const label = query ? `${this.createLabelValue} « ${query} »` : this.createLabelValue
      list.appendChild(this.rowNode({ value: query, label: label }, { create: true, enabled: !!query }))
    }

    this.listTarget.replaceChildren(list)
  }

  // Accents and case aside, an existing entry beats a duplicate.
  hasExactMatch(rows, query) {
    if (!query) return false
    const fold = (s) => s.normalize("NFD").replace(/\p{Diacritic}/gu, "").toLowerCase().trim()
    return rows.some((r) => fold(r.label) === fold(query) || fold(r.value) === fold(query))
  }

  rowNode(row, { none = false, create = false, enabled = true } = {}) {
    const li = this.el("li", "picker-layer__row")
    const disabledReason = this.request.disabled?.[row.value]

    const button = document.createElement("button")
    button.type = "button"
    button.className = [
      "picker-row",
      none && "picker-row--none",
      create && "picker-row--create",
      disabledReason && "picker-row--disabled",
      row.value !== "" && row.value === this.request.selected && "picker-row--selected"
    ].filter(Boolean).join(" ")
    button.disabled = !!disabledReason || (create && !enabled)

    button.appendChild(this.iconNode(row, { none, create }))
    button.appendChild(this.el("span", "picker-row__label", row.label))
    if (disabledReason) button.appendChild(this.el("span", "picker-row__meta", disabledReason))
    else if (row.meta) button.appendChild(this.el("span", "picker-row__meta", row.meta))

    button.addEventListener("click", () => this.choose(row, none, create))
    li.appendChild(button)
    return li
  }

  // The emoji already in the name becomes the icon; without one, the initial —
  // never a generic glyph, which would read as a system category (Tour 32b-2).
  iconNode(row, { none, create }) {
    if (create) return this.el("span", "picker-row__icon picker-row__icon--create", "+")
    if (none) return this.el("span", "picker-row__icon picker-row__icon--none", "—")
    if (row.icon) return this.el("span", "picker-row__icon", row.icon)
    return this.el("span", "picker-row__icon picker-row__icon--initial", (row.label || "?").trim()[0].toUpperCase())
  }

  choose(row, none, create) {
    const typed = this.searchTarget.value.trim()
    const next = this.request.onSelect(none ? null : row, create ? typed : null)
    if (next) return this.present(next)
    if (history.state?.pickerLayer) history.back(); else this.close()
  }

  _onPop() {
    // The entry we pushed is already gone; just take the layer down with it.
    this.isOpen = false
    this.rootTarget.classList.remove("picker-layer--open")
    document.body.classList.remove("picker-layer-open")
    window.removeEventListener("popstate", this._onPop)
    document.removeEventListener("keydown", this._onKeydown)
    setTimeout(() => { if (!this.isOpen) this.rootTarget.hidden = true }, 200)
  }

  _onKeydown(event) {
    if (event.key === "Escape") { event.stopPropagation(); this.back() }
  }

  el(tag, className, text) {
    const node = document.createElement(tag)
    node.className = className
    if (text !== undefined) node.textContent = text
    return node
  }
}
