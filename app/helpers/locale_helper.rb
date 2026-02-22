module LocaleHelper
  # Helper method to generate URLs with current locale
  def url_with_locale(path, locale = I18n.locale)
    if locale == I18n.default_locale
      path
    else
      "/#{locale}#{path}"
    end
  end

  # Helper method for language switcher
  def language_links
    content_tag :div, class: "flex space-x-2" do
      I18n.available_locales.map do |locale|
        link_to locale.to_s.upcase,
                params.permit!.merge(locale: locale),
                class: "px-2 py-1 text-xs rounded #{locale_link_class(locale)}"
      end.join.html_safe
    end
  end

  private

  def locale_link_class(locale)
    if I18n.locale == locale
      "bg-primary text-white"
    else
      "bg-secondary text-gray-700 hover:bg-primary hover:text-white"
    end
  end
end
