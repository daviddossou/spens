# frozen_string_literal: true

namespace :release do
  desc "Run post-deploy tasks"
  task run_after: :environment do
    Rake::Task["transactions:backfill_transfer_groups"].invoke
  end
end
