# frozen_string_literal: true

# Sent once, right after sign-up. The stamp makes a retried job harmless.
class WelcomeEmailJob < ApplicationJob
  queue_as :default

  def perform(user, locale)
    return if user.welcome_email_sent_at? || !user.lifecycle_emails?

    LifecycleMailer.welcome(user, locale).deliver_now
    user.update_column(:welcome_email_sent_at, Time.current)
    Analytics.track(user, "lifecycle_email_sent", email: "welcome", locale: locale.to_s)
  end
end
