# frozen_string_literal: true

# The one-off "come back and add your accounts" nudge, for a member who asked to be reminded
# later at onboarding step 2. Sent once, then forgotten; pointless once an account exists.
class Onboarding::AccountsNudge
  DELAYS = {
    "1h" => ->(zone) { zone.now + 1.hour },
    "tonight" => ->(zone) { now = zone.now; now.hour < 19 ? now.change(hour: 20) : now + 1.hour },
    "tomorrow" => ->(zone) { zone.now.tomorrow.change(hour: 9) }
  }.freeze

  def initialize(membership)
    @membership = membership
  end

  def deliver
    @membership.update_column(:accounts_nudge_at, nil)
    return :skipped if @membership.space.accounts.active.exists? || @membership.space.onboarding_completed?

    channel = push_delivered? ? :push : :email
    OnboardingMailer.accounts_nudge(@membership).deliver_later if channel == :email
    Analytics.track(@membership.user, "onboarding_accounts_nudge_sent", channel: channel.to_s)
    channel
  end

  private

  def push_delivered?
    I18n.with_locale(locale) do
      Reminders::WebPushDelivery.new(@membership.user).call(
        title: I18n.t("onboarding.accounts_nudge.title"), body: I18n.t("onboarding.accounts_nudge.body"),
        url: Rails.application.routes.url_helpers.onboarding_account_setups_path(locale: locale)
      ).positive?
    end
  end

  def locale
    @membership.space.locale.presence || I18n.default_locale
  end
end
