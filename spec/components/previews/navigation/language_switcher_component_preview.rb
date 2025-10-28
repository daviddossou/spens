# frozen_string_literal: true

class Navigation::LanguageSwitcherComponentPreview < ViewComponent::Preview
  def default
    render Navigation::LanguageSwitcherComponent.new(
      current_locale: :en,
      available_locales: [ :en, :fr ],
      params: {}
    )
  end

  def multilingual_app
    render Navigation::LanguageSwitcherComponent.new(
      current_locale: :es,
      available_locales: [ :en, :fr, :es, :de, :it ],
      params: {}
    )
  end

  def with_page_state
    render Navigation::LanguageSwitcherComponent.new(
      current_locale: :en,
      available_locales: [ :en, :fr ],
      params: { page: 2, search: "financial goals", category: "savings" }
    )
  end

  def single_language_edge_case
    render Navigation::LanguageSwitcherComponent.new(
      current_locale: :en,
      available_locales: [ :en ],
      params: {}
    )
  end
end
