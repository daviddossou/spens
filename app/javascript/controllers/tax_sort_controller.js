import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Drag-and-drop reordering of taxonomy siblings (parent groups, or children within a
// group). Dragging is restricted to this container; dropping PATCHes the new key order.
export default class extends Controller {
  static values = { url: String, draggable: String }

  connect() {
    this.sortable = Sortable.create(this.element, {
      handle: ".admin-tree-row__handle",
      draggable: this.draggableValue || ".admin-tree-row",
      animation: 150,
      // Pointer-event drag instead of native HTML5 DnD: consistent on touch devices
      // (the admin is used on phones) and in headless verification.
      forceFallback: true,
      onEnd: () => this.save()
    })
  }

  disconnect() {
    this.sortable?.destroy()
  }

  async save() {
    const keys = [...this.element.querySelectorAll(":scope > [data-key]")].map((el) => el.dataset.key)
    await fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
        "Accept": "application/json"
      },
      body: JSON.stringify({ keys })
    })
  }
}
