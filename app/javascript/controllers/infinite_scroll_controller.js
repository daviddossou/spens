import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="infinite-scroll"
export default class extends Controller {
  static targets = ["trigger", "spinner"]
  static values = {
    url: String,
    page: Number
  }

  connect() {
    this.observeTrigger()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  // Stimulus calls this automatically when a new trigger target appears in the DOM
  triggerTargetConnected(element) {
    this.ensureObserver()
    this.observer.observe(element)
  }

  triggerTargetDisconnected(element) {
    this.observer.unobserve(element)
  }

  handleIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting && this.pageValue) {
        this.loadMore()
      }
    })
  }

  async loadMore() {
    if (this.loading) return

    this.loading = true
    this.showSpinner()

    try {
      const response = await fetch(`${this.urlValue}?page=${this.pageValue}`, {
        headers: {
          'Accept': 'text/vnd.turbo-stream.html'
        }
      })

      if (response.ok) {
        const html = await response.text()
        this.pageValue++
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error('Error loading more content:', error)
    } finally {
      this.loading = false
      this.hideSpinner()
    }
  }

  showSpinner() {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.remove('hidden')
    }
  }

  hideSpinner() {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add('hidden')
    }
  }

  observeTrigger() {
    if (this.hasTriggerTarget) {
      this.ensureObserver()
      this.observer.observe(this.triggerTarget)
    }
  }

  ensureObserver() {
    if (!this.observer) {
      this.observer = new IntersectionObserver(
        (entries) => this.handleIntersection(entries),
        { rootMargin: '200px' }
      )
    }
  }
}
