# frozen_string_literal: true

namespace :cohorts do
  # bin/rails "cohorts:activate[cohorte-dec,https://chat.whatsapp.com/...]"
  # Idempotent; the URL is optional and kept from before when omitted.
  desc "Create/activate the cohort whose campaign tags the /c/<code> links"
  task :activate, [ :campaign, :group_url ] => :environment do |_, args|
    cohort = Cohort.activate!(args[:campaign], group_url: args[:group_url])
    puts "Active cohort: #{cohort.campaign} (group: #{cohort.whatsapp_group_url || 'not set'})"
  end

  # The /cohorte page switches to "promo complète": a human decision, WhatsApp
  # does not expose the group's size.
  desc "Close the active cohort's registrations (the sign-up page offers the wait list)"
  task close: :environment do
    puts "Registrations closed: #{Cohort.current!.tap { |c| c.update!(registrations_closed: true) }.campaign}"
  end

  desc "Reopen the active cohort's registrations"
  task reopen: :environment do
    puts "Registrations open: #{Cohort.current!.tap { |c| c.update!(registrations_closed: false) }.campaign}"
  end
end
