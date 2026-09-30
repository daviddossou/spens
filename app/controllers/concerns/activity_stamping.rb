# frozen_string_literal: true

# Keeps users.last_active_at fresh at a cost of at most one write per user per hour, and
# mirrors the calendar day to Brevo (LAST_ACTIVE_AT) the first time the user shows up each day.
module ActivityStamping
  extend ActiveSupport::Concern

  STAMP_EVERY = 1.hour

  included do
    before_action :stamp_activity
  end

  private

  def stamp_activity
    return unless user_signed_in? && !impersonating?

    user = current_user
    previous = user.last_active_at
    return if previous && previous > STAMP_EVERY.ago

    now = Time.current
    user.update_column(:last_active_at, now)
    return if previous && previous.to_date == now.to_date

    Brevo.upsert_contact_later(email: user.email, attributes: { LAST_ACTIVE_AT: now.to_date.iso8601 })
  end
end
