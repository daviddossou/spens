# frozen_string_literal: true

namespace :release do
  desc "Run post-deploy tasks"
  task run_after: :environment do
    Rake::Task["memberships:backfill"].invoke
  end
end
