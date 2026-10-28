# frozen_string_literal: true

namespace :cohorts do
  # bin/rails "cohorts:activate[cohorte-dec,https://chat.whatsapp.com/...]"
  # Idempotent; the URL is optional and kept from before when omitted.
  desc "Create/activate the cohort whose campaign tags the /c/<code> links"
  task :activate, [ :campaign, :group_url ] => :environment do |_, args|
    cohort = Cohort.activate!(args[:campaign], group_url: args[:group_url])
    puts "Active cohort: #{cohort.campaign} (group: #{cohort.whatsapp_group_url || 'not set'})"
  end
end
