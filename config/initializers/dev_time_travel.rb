# frozen_string_literal: true

# DEV-ONLY time travel, OPT-IN via a single env var. Fully inert unless BOTH:
#   - Rails.env.development?
#   - ENV["DEV_TIME_TRAVEL"] holds a parseable datetime
# When off, nothing is prepended and no middleware is added — real clock only.
#
# To enable (for demo data / screenshots): set the instant in the web container's
# env and restart web, e.g.
#   DEV_TIME_TRAVEL="2026-08-28 12:00:00"   (docker-compose or shell)
#   docker compose restart web
# Unset it (or leave it blank) to return to the real clock.
#
# The app uses zone-aware Time.current / Date.current everywhere (no raw
# Date.today / Time.now), so overriding the current TimeZone is sufficient.
if Rails.env.development? && ENV["DEV_TIME_TRAVEL"].to_s.strip.present?
  module DevTimeTravel
    # The configured instant, or nil if it can't be parsed (then: real clock).
    def self.override
      Time.find_zone("UTC").parse(ENV["DEV_TIME_TRAVEL"].to_s.strip)
    rescue StandardError
      nil
    end
  end

  # Honour a per-thread override on the zone-aware clock. Falls straight through
  # to the real clock when no override is set for the current thread.
  module ZoneTimeTravel
    def now
      (t = Thread.current[:dev_fake_now]) ? t.in_time_zone(self) : super
    end

    def today
      (t = Thread.current[:dev_fake_now]) ? t.in_time_zone(self).to_date : super
    end
  end
  ActiveSupport::TimeZone.prepend(ZoneTimeTravel)

  # Set the override for the duration of each request, then clear it.
  class DevTimeTravelMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      Thread.current[:dev_fake_now] = DevTimeTravel.override
      @app.call(env)
    ensure
      Thread.current[:dev_fake_now] = nil
    end
  end
  Rails.application.config.middleware.use DevTimeTravelMiddleware
end
