# frozen_string_literal: true

# Manage admin access from a console/CLI (e.g. `kamal app exec` in production), since the first
# admin can't be granted from inside the gated admin area. After that, admins can grant/revoke
# each other from /admin.
#
#   bin/rails "admin:grant[you@example.com]"
#   bin/rails "admin:revoke[someone@example.com]"
#   bin/rails admin:list
namespace :admin do
  desc "Grant admin access to a user by email"
  task :grant, [ :email ] => :environment do |_t, args|
    AdminTask.set(args[:email], true)
  end

  desc "Revoke admin access from a user by email"
  task :revoke, [ :email ] => :environment do |_t, args|
    AdminTask.set(args[:email], false)
  end

  desc "List the current admins"
  task list: :environment do
    emails = User.where(admin: true).order(:email).pluck(:email)
    abort("No admins yet.") if emails.empty?
    puts "Admins (#{emails.size}):"
    emails.each { |email| puts "  - #{email}" }
  end

  module AdminTask
    def self.set(email, admin)
      abort("Usage: bin/rails \"admin:#{admin ? 'grant' : 'revoke'}[email@example.com]\"") if email.blank?

      user = User.find_by(email: email.strip)
      abort("No user with email #{email.strip.inspect}.") unless user

      user.update!(admin: admin)
      puts "#{user.email} is #{admin ? 'now an admin' : 'no longer an admin'}."
    end
  end
end
