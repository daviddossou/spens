# frozen_string_literal: true

# Runs every request in the user's time zone so Date.current, Time.current and
# l(timestamp) are local. The zone is captured from the device by JS (see
# time_zone_controller.js); fallback is the space's zone, then West Africa.
module TimeZoneScoping
  extend ActiveSupport::Concern

  DEFAULT_TIME_ZONE = "Africa/Porto-Novo"

  included do
    around_action :use_user_time_zone
  end

  private

  def use_user_time_zone(&block)
    Time.use_zone(resolved_time_zone, &block)
  end

  def resolved_time_zone
    candidate = current_user&.time_zone.presence || current_space&.time_zone.presence
    (candidate && Time.find_zone(candidate)) || DEFAULT_TIME_ZONE
  end
end
