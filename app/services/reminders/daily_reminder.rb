# frozen_string_literal: true

# The evening nudge for one member of one space. Sent at most once a day, at the member's
# chosen hour on their own clock, and only if they recorded nothing today. A push goes to
# their subscribed browsers; with none reachable, an e-mail goes instead.
class Reminders::DailyReminder
  def initialize(membership)
    @membership = membership
  end

  def due?
    now = @membership.time_zone.now

    @membership.reminder_enabled? && now.hour == @membership.reminder_hour &&
      @membership.reminder_last_sent_on != now.to_date && @membership.space.onboarding_completed? &&
      !@membership.noted_today?
  end

  # Returns the channel used (:push, :email) or nil when nothing was due.
  def deliver
    return unless due?

    # Claimed first, so a retry or an overlapping run never sends twice.
    @membership.update_column(:reminder_last_sent_on, @membership.time_zone.today)
    channel = push_delivered? ? :push : :email
    ReminderMailer.daily(@membership).deliver_later if channel == :email

    Analytics.track(@membership.user, "reminder_sent", channel: channel.to_s, hour: @membership.reminder_hour)
    channel
  end

  private

  def push_delivered?
    I18n.with_locale(locale) do
      Reminders::WebPushDelivery.new(@membership.user).call(
        title: I18n.t("reminders.daily.title"), body: I18n.t("reminders.daily.body"),
        url: Rails.application.routes.url_helpers.dashboard_path(locale: locale, reminder: 1)
      ).positive?
    end
  end

  def locale
    @membership.space.locale.presence || I18n.default_locale
  end
end
