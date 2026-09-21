# frozen_string_literal: true

# Runs at the top of every hour (config/recurring.yml): each member whose chosen hour it is,
# on their own clock, gets their reminder.
class Reminders::DispatchJob < ApplicationJob
  queue_as :default

  def perform
    Membership.reminding.includes(:user, :space).find_each do |membership|
      Reminders::DailyReminder.new(membership).deliver
    rescue StandardError => e
      Rails.logger.error("[Reminders] membership #{membership.id}: #{e.class} #{e.message}")
    end
  end
end
