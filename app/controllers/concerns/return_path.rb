# frozen_string_literal: true

# Where to land once signed in, when a link asked for a precise screen (cohort
# links). Kept in session across sign-in, sign-up and onboarding; forgotten
# after a day so a stale click does not hijack a later sign-in.
module ReturnPath
  extend ActiveSupport::Concern

  SESSION_KEY = :return_path
  TTL = 1.day

  private

  def remember_return_path(path)
    session[SESSION_KEY] = { "path" => path, "at" => Time.current.iso8601 }
  end

  # Consumes the stored path; nil when absent, expired or not a local path.
  def consume_return_path
    stored = session.delete(SESSION_KEY)
    return unless stored.is_a?(Hash) && stored["path"].present?
    return if Time.iso8601(stored["at"].to_s) < TTL.ago

    url_from(stored["path"])
  rescue ArgumentError
    nil
  end
end
