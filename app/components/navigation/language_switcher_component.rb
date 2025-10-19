# frozen_string_literal: true

class Navigation::LanguageSwitcherComponent < Ui::SwitcherComponent
  def initialize(current_locale: I18n.locale, available_locales: I18n.available_locales, params: {})
    @current_locale = current_locale
    @available_locales = available_locales
    @params = params

    super(
      options: locale_options,
      current: current_locale
    )
  end

  private

  attr_reader :current_locale, :available_locales, :params

  def locale_options
    available_locales.map do |locale|
      {
        text: locale.to_s.upcase,
        value: locale,
        url: locale_url(locale),
        data: { "turbo-method": "get" }
      }
    end
  end

  def locale_url(locale)
    if params.respond_to?(:permit!)
      params.permit!.merge(locale: locale)
    else
      params.merge(locale: locale)
    end
  end
end
