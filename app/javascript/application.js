// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker.js")
}

// Clean up body scroll lock before Turbo caches the page
document.addEventListener("turbo:before-cache", () => {
  document.body.classList.remove("bottom-sheet-open")
})
