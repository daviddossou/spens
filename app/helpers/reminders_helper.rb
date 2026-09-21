# frozen_string_literal: true

module RemindersHelper
  # "20 h" / "8 PM"
  def reminder_hour_label(hour)
    l(Time.zone.now.change(hour: hour, min: 0), format: t("reminders.hour_format"))
  end

  # Data attributes wiring an element to push_controller.js.
  def push_data
    { controller: "push", push_key_value: Rails.application.config.x.web_push&.dig(:public_key).to_s,
      push_url_value: push_subscription_path }
  end
end
