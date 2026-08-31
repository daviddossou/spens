# frozen_string_literal: true

namespace :release do
  # Invoked on every deploy by .kamal/hooks/post-deploy. Chain one-off post-deploy
  # tasks (e.g. data backfills) here, then remove them once they've shipped.
  desc "Run post-deploy tasks"
  task run_after: :environment do
    Rake::Task["transactions:convert_onboarding_initial_balances"].invoke
  end
end
