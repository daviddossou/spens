module LocaleHelper
  # Helper method to generate URLs with current locale
  def url_with_locale(path, locale = I18n.locale)
    if locale == I18n.default_locale
      path
    else
      "/#{locale}#{path}"
    end
  end
end
