# frozen_string_literal: true

namespace :memberships do
  desc "Backfill memberships for existing spaces and user_id on records"
  task backfill: :environment do
    puts "Creating memberships for existing spaces..."
    Space.find_each do |space|
      Membership.find_or_create_by!(user_id: space.user_id, space_id: space.id)
    end
    puts "  Created #{Membership.count} memberships"

    puts "Backfilling user_id on transactions..."
    Transaction.includes(:space).where(user_id: nil).find_each do |txn|
      txn.update_columns(user_id: txn.space.user_id)
    end

    puts "Backfilling user_id on debts..."
    Debt.includes(:space).where(user_id: nil).find_each do |debt|
      debt.update_columns(user_id: debt.space.user_id)
    end

    puts "Backfilling user_id on accounts..."
    Account.includes(:space).where(user_id: nil).find_each do |account|
      account.update_columns(user_id: account.space.user_id)
    end

    puts "Done!"
  end
end
