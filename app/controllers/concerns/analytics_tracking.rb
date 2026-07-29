# frozen_string_literal: true

# Auto-captures a PostHog event for every successful mutating request (POST/PATCH/PUT/DELETE)
# by any signed-in user, e.g. "budgets#create". Curated events (transaction_created,
# quick_add_used, ...) carry richer properties and are tracked explicitly in their controllers.
module AnalyticsTracking
  extend ActiveSupport::Concern

  included do
    after_action :capture_analytics_event
  end

  private

  def capture_analytics_event
    return unless request.method.in?(%w[POST PATCH PUT DELETE])
    return unless response.successful? || response.redirection?
    return unless respond_to?(:current_user, true) && current_user

    Analytics.track(
      current_user,
      "#{controller_path}##{action_name}",
      method: request.method,
      status: response.status,
      space_id: (current_space.id if respond_to?(:current_space, true) && current_space)
    )
  end
end
