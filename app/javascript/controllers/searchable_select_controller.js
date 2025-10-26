import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="searchable-select"
export default class extends Controller {
  connect() {
    if (typeof TomSelect !== 'undefined') {
      this.initializeTomSelect()
    } else {
      const checkTomSelect = setInterval(() => {
        if (typeof TomSelect !== 'undefined') {
          clearInterval(checkTomSelect)
          this.initializeTomSelect()
        }
      }, 100)

      // Timeout after 5 seconds
      setTimeout(() => {
        clearInterval(checkTomSelect)
        if (typeof TomSelect === 'undefined') {
          console.error("TomSelect failed to load from CDN")
        }
      }, 5000)
    }
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy()
    }
  }

  initializeTomSelect() {
    const options = {
      plugins: ['dropdown_input'],
      maxOptions: null,
      sortField: null,
      placeholder: this.element.dataset.placeholder,
      allowEmptyOption: true,
      lockOptgroupOrder: true, // Prevent reordering of optgroups
      render: {
        option: function (data, escape) {
          // Handle divider options - check if the option has the 'option-divider' class or special value
          if ((data.$option && data.$option.classList && data.$option.classList.contains('option-divider')) ||
            data.value === '___divider___') {
            return '<div class="divider"></div>'
          }
          return '<div>' + escape(data.text) + '</div>'
        },
        item: function (data, escape) {
          return '<div>' + escape(data.text) + '</div>'
        }
      }
    }

    this.tomSelect = new TomSelect(this.element, options)
  }
}
