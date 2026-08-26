# frozen_string_literal: true

namespace :release do
  # Invoked on every deploy by .kamal/hooks/post-deploy. Chain one-off post-deploy
  # tasks (e.g. data backfills) here, then remove them once they've shipped.
  desc "Run post-deploy tasks"
  task run_after: :environment do
    Rake::Task["transaction_types:sync_template_names"].invoke
    Rake::Task["backfill:savings_goals_to_model"].invoke
  end
end
