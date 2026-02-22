import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="infinite-scroll"
export default class extends Controller {
  static targets = ["trigger", "spinner"]
  static values = {
    url: String,
    page: Number
  }

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersection(entries),
      { rootMargin: '100px' }
    )

    if (this.hasTriggerTarget) {
      this.observer.observe(this.triggerTarget)
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
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
    this.hideTrigger()

    try {
      const response = await fetch(`${this.urlValue}?page=${this.pageValue}`, {
        headers: {
          'Accept': 'text/vnd.turbo-stream.html'
        }
      })

      if (response.ok) {
        const html = await response.text()
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

  hideTrigger() {
    if (this.hasTriggerTarget) {
      this.triggerTarget.style.display = 'none'
    }
  }
}
