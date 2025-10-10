# frozen_string_literal: true

class Navigation::LanguageSwitcherComponentPreview < ViewComponent::Preview
  # Default language switcher (EN/FR)
  def default
    render Navigation::LanguageSwitcherComponent.new(
      current_locale: :en,
      available_locales: [ :en, :fr ],
      params: {}
    )
  end

  # With current locale as French
  def french_selected
    render Navigation::LanguageSwitcherComponent.new(
      current_locale: :fr,
      available_locales: [ :en, :fr ],
      params: {}
    )
  end

  # Multiple languages
  def multiple_languages
    render Navigation::LanguageSwitcherComponent.new(
      current_locale: :en,
      available_locales: [ :en, :fr, :es, :de, :it ],
      params: {}
    )
  end

  # With existing parameters (simulating page state)
  def with_parameters
    render Navigation::LanguageSwitcherComponent.new(
      current_locale: :en,
      available_locales: [ :en, :fr ],
      params: { page: 2, search: "test query", filter: "active" }
    )
  end

  # Single language (edge case)
  def single_language
    render Navigation::LanguageSwitcherComponent.new(
      current_locale: :en,
      available_locales: [ :en ],
      params: {}
    )
  end

  # Many languages (stress test)
  def many_languages
    render Navigation::LanguageSwitcherComponent.new(
      current_locale: :en,
      available_locales: [ :en, :fr, :es, :de, :it, :pt, :nl, :pl, :ru, :ja, :zh, :ar ],
      params: {}
    )
  end

  # No current locale (nil case)
  def no_current_locale
    render Navigation::LanguageSwitcherComponent.new(
      current_locale: nil,
      available_locales: [ :en, :fr ],
      params: {}
    )
  end

  # Empty locales (edge case)
  def empty_locales
    render Navigation::LanguageSwitcherComponent.new(
      current_locale: :en,
      available_locales: [],
      params: {}
    )
  end

  # Different styling showcase
  def styling_showcase
    render_with_template locals: {
      components: [
        {
          title: "Default (EN selected)",
          component: Navigation::LanguageSwitcherComponent.new(
            current_locale: :en,
            available_locales: [ :en, :fr ],
            params: {}
          )
        },
        {
          title: "French selected",
          component: Navigation::LanguageSwitcherComponent.new(
            current_locale: :fr,
            available_locales: [ :en, :fr ],
            params: {}
          )
        },
        {
          title: "Multiple languages",
          component: Navigation::LanguageSwitcherComponent.new(
            current_locale: :es,
            available_locales: [ :en, :fr, :es, :de ],
            params: {}
          )
        }
      ]
    }
  end
end
