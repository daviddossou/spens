# frozen_string_literal: true

# DEV-ONLY time travel, for building demo data and taking screenshots.
#
# When tmp/fake_now.txt exists and holds a parseable datetime (e.g.
# "2026-08-28 12:00:00"), every web request sees that instant as "now".
# The app uses zone-aware Time.current / Date.current everywhere (no raw
# Date.today / Time.now), so overriding the current TimeZone is sufficient.
#
# Change the date by editing the file — no restart needed. Disable by deleting
# the file, or remove this initializer entirely (then restart web).
if Rails.env.development?
  module DevTimeTravel
    FILE = Rails.root.join("tmp", "fake_now.txt")

    # Parsed override for the current request, or nil when disabled.
    def self.override
      return nil unless File.exist?(FILE)

      raw = File.read(FILE).strip
      raw.empty? ? nil : Time.find_zone("UTC").parse(raw)
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
