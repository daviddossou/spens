# frozen_string_literal: true

# Accompaniment e-mails (welcome, later nudges). Each carries a one-click unsubscribe and
# its own open/click tracking through EmailEventsController.
class LifecycleMailer < ApplicationMailer
  def welcome(user, locale = I18n.default_locale)
    @user = user
    token = user.signed_id(purpose: :email_events)
    @open_url = email_click_url(email: "welcome", token: token, locale: locale)
    @pixel_url = email_open_url(email: "welcome", token: token, format: :gif)
    @home_url = root_url(locale: locale)
    @stop_url = email_unsubscribe_url(token: user.signed_id(purpose: :lifecycle_emails), locale: locale)
    headers["List-Unsubscribe"] = "<#{@stop_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"

    I18n.with_locale(locale) { mail(to: user.email, subject: t("lifecycle_emails.welcome.subject")) }
  end
end
