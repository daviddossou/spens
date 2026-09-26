# frozen_string_literal: true

class OnboardingMailer < ApplicationMailer
  def accounts_nudge(membership)
    locale = membership.space.locale.presence || I18n.default_locale
    @open_url = onboarding_account_setups_url(locale: locale)

    I18n.with_locale(locale) { mail(to: membership.user.email, subject: t("onboarding.accounts_nudge.title")) }
  end
end
