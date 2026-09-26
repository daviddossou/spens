# frozen_string_literal: true

# Every 10 minutes (config/recurring.yml): sends the "add your accounts" nudges that are due.
class Onboarding::AccountsNudgeJob < ApplicationJob
  queue_as :default

  def perform
    Membership.nudge_due.includes(:user, :space).find_each do |membership|
      Onboarding::AccountsNudge.new(membership).deliver
    rescue StandardError => e
      Rails.logger.error("[AccountsNudge] membership #{membership.id}: #{e.class} #{e.message}")
    end
  end
end
