# frozen_string_literal: true

namespace :users do
  # One-off: estimate last_active_at for rows created before the column existed, then mirror
  # every user's lifecycle attributes to Brevo. Safe to re-run.
  desc "Backfill users.last_active_at and push lifecycle attributes to Brevo"
  task backfill_last_active_at: :environment do
    Brevo.ensure_attributes
    User.find_each do |user|
      if user.last_active_at.nil? && (at = Users::LastActivityEstimate.call(user))
        user.update_column(:last_active_at, at)
      end
      Brevo.upsert_contact_later(email: user.email, attributes: Brevo.lifecycle_attributes(user))
    end
  end
end
