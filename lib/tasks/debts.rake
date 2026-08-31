# frozen_string_literal: true

namespace :debts do
  desc "Close debts that are fully reimbursed but still marked ongoing (pre-callback data)"
  task settle_fully_reimbursed: :environment do
    scope = Debt.ongoing.where("total_lent > 0 AND total_reimbursed >= total_lent")
    count = scope.update_all(status: "paid", updated_at: Time.current)
    Rails.logger.info "[debts:settle_fully_reimbursed] closed #{count} fully-reimbursed debt(s)"
  end

  desc "Merge duplicate debts (same space, direction and case-insensitive name) left by the old system"
  task merge_duplicate_names: :environment do
    dry_run = ENV["DRY_RUN"].present?
    merged = 0
    Debt.find_each.group_by { |d| [ d.space_id, d.direction, d.name.to_s.strip.downcase ] }
        .each_value do |debts|
      next if debts.size < 2

      keeper, *dupes = debts.sort_by(&:created_at)
      if dry_run
        puts "would merge #{dupes.size} into #{keeper.name.strip} (#{keeper.direction}, space #{keeper.space_id}): " \
             "#{debts.map { |d| "#{d.name.inspect} #{d.status} lent=#{d.total_lent} reimb=#{d.total_reimbursed}" }.join(' | ')}"
        merged += dupes.size
        next
      end

      ActiveRecord::Base.transaction do
        dupes.each do |dupe|
          Transaction.where(debt_id: dupe.id).update_all(debt_id: keeper.id)
          keeper.total_lent = (keeper.total_lent || 0) + (dupe.total_lent || 0)
          keeper.total_reimbursed = (keeper.total_reimbursed || 0) + (dupe.total_reimbursed || 0)
          dupe.destroy!
          merged += 1
        end
        # The merged record stays ongoing if any side still was; a fully-repaid
        # result closes itself like any other debt.
        keeper.status = "ongoing" if debts.any?(&:ongoing?)
        keeper.status = "paid" if keeper.ongoing? && keeper.total_lent.to_f.positive? && keeper.remaining_balance <= 0
        keeper.name = keeper.name.strip
        keeper.save!
      end
    end
    Rails.logger.info "[debts:merge_duplicate_names] merged #{merged} duplicate debt(s)#{' (dry run)' if dry_run}"
    puts "#{dry_run ? 'would merge' : 'merged'} #{merged} duplicate debt(s)"
  end
end
