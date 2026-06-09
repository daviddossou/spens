# frozen_string_literal: true

namespace :categories do
  desc "File every space's existing transaction types into the category tree (non-destructive, idempotent)"
  task backfill: :environment do
    total = Space.count
    Space.find_each.with_index(1) do |space, i|
      BackfillCategoryHierarchy.new(space).call
      print "\rBackfilled #{i}/#{total} spaces"
    end
    puts "\nDone."
  end
end
