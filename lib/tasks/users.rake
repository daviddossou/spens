# frozen_string_literal: true

namespace :users do
  # Accounts created before deferred confirmation all entered an OTP at sign-up.
  desc "Mark pre-existing users as email-confirmed"
  task backfill_confirmed_at: :environment do
    count = User.where(confirmed_at: nil).update_all("confirmed_at = created_at")
    puts "users:backfill_confirmed_at — #{count} user(s) confirmed"
  end
end
