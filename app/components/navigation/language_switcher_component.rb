# frozen_string_literal: true

class Navigation::LanguageSwitcherComponent < ViewComponent::Base
  def initialize(current_locale: I18n.locale, available_locales: I18n.available_locales, params: {})
    @current_locale = current_locale
    @available_locales = available_locales
    @params = params
  end

  private

  attr_reader :current_locale, :available_locales, :params

  def link_classes(locale)
    base_classes = 'px-2 py-1 text-xs rounded transition-colors'

    if current_locale == locale
      "#{base_classes} #{active_classes}"
    else
      "#{base_classes} #{inactive_classes}"
    end
  end

  def active_classes
    'bg-primary text-white'
  end

  def inactive_classes
    'bg-off-white text-gray-700 hover:bg-primary hover:text-white'
  end

  def locale_url(locale)
    if params.respond_to?(:permit!)
      params.permit!.merge(locale: locale)
    else
      params.merge(locale: locale)
    end
  end
end
