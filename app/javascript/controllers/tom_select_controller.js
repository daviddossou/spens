import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

// Connects to data-controller="tom-select"
export default class extends Controller {
  static values = {
    options: Object,
    url: String,
    allowCreate: Boolean,
    placeholder: String,
    maxItems: Number,
    suggestions: Array,
    defaultSuggestions: Array
  }

  connect() {
    const config = this.defaultConfig()

    // Merge with custom options from data attribute
    const customOptions = this.hasOptionsValue ? this.optionsValue : {}
    const finalConfig = { ...config, ...customOptions }

    this.tomSelect = new TomSelect(this.element, finalConfig)
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy()
    }
  }

  defaultConfig() {
    const config = {
      create: this.hasAllowCreateValue ? this.allowCreateValue : false,
      placeholder: this.hasPlaceholderValue ? this.placeholderValue : "Type to search...",
      maxItems: this.hasMaxItemsValue ? this.maxItemsValue : 1,
      onInitialize: function () {
        const tomSelect = this

        this.on('change', function () {
          const input = tomSelect.control_input
          if (input && tomSelect.items.length > 0) {
            input.placeholder = ''
          } else {
            input.placeholder = config.placeholder
          }
        })

        this.on('dropdown_open', function () {
          if (tomSelect.items.length > 0) {
            tomSelect.setTextboxValue('')
          }
        })
      },
      // For autocomplete on text inputs, show suggestions as user types
      openOnFocus: true,
      // Allow typing beyond the suggestions
      createOnBlur: true,
      highlight: true
    }

    // If suggestions are provided (for text input autocomplete)
    if (this.hasSuggestionsValue && this.suggestionsValue.length > 0) {
      const allOptions = this.suggestionsValue.map(item => {
        if (typeof item === 'string') {
          return { value: item, text: item }
        }
        return item
      })

      // If default suggestions are provided, use them initially
      if (this.hasDefaultSuggestionsValue && this.defaultSuggestionsValue.length > 0) {
        config.options = this.defaultSuggestionsValue.map(item => {
          if (typeof item === 'string') {
            return { value: item, text: item }
          }
          return item
        })

        // Override load to filter through all suggestions when typing
        config.load = (query, callback) => {
          if (!query.length) {
            // Show default suggestions when empty
            callback(config.options)
            return
          }

          // Filter through all suggestions when typing
          const filtered = allOptions.filter(option =>
            option.text.toLowerCase().includes(query.toLowerCase())
          )
          callback(filtered)
        }
      } else {
        // No default suggestions, use all suggestions
        config.options = allOptions
      }

      config.labelField = 'text'
      config.valueField = 'value'
      config.searchField = ['text']
    }

    // If URL is provided, load options from remote source
    if (this.hasUrlValue) {
      config.load = (query, callback) => {
        const url = `${this.urlValue}?q=${encodeURIComponent(query)}`
        fetch(url)
          .then(response => response.json())
          .then(json => {
            callback(json)
          })
          .catch(() => {
            callback()
          })
      }
    }

    return config
  }

  // Public method to update options programmatically
  updateOptions(options) {
    if (this.tomSelect) {
      this.tomSelect.clearOptions()
      this.tomSelect.addOptions(options)
    }
  }

  // Public method to get current value
  getValue() {
    return this.tomSelect ? this.tomSelect.getValue() : null
  }

  // Public method to set value
  setValue(value) {
    if (this.tomSelect) {
      this.tomSelect.setValue(value)
    }
  }
}
