# frozen_string_literal: true

class ReminderMailer < ApplicationMailer
  def daily(membership)
    locale = membership.space.locale.presence || I18n.default_locale
    @open_url = dashboard_url(locale: locale, reminder: 1)
    @stop_url = reminder_unsubscribe_url(token: membership.signed_id(purpose: :reminder), locale: locale)
    headers["List-Unsubscribe"] = "<#{@stop_url}>"

    I18n.with_locale(locale) { mail(to: membership.user.email, subject: t("reminders.daily.title")) }
  end
end
