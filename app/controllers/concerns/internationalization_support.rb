# frozen_string_literal: true

module InternationalizationSupport
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  protected

  def set_locale
    locale = space_locale || params[:locale] || session[:locale] || extract_locale_from_accept_language_header || I18n.default_locale

    locale = I18n.default_locale unless I18n.available_locales.include?(locale.to_sym)

    I18n.locale = locale
    session[:locale] = locale
  end

  private

  # The space's locale is the source of truth for signed-in users; URL and
  # session only apply to public pages (landing, auth).
  def space_locale
    return nil unless respond_to?(:current_space, true)

    current_space&.locale.presence
  end

  def extract_locale_from_accept_language_header
    return nil unless request.env["HTTP_ACCEPT_LANGUAGE"]

    request.env["HTTP_ACCEPT_LANGUAGE"].scan(/^[a-z]{2}/).first
  end
end
