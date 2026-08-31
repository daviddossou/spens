# frozen_string_literal: true

namespace :transactions do
  desc "Pair existing transfer legs (transfer_out + transfer_in) sharing a transfer_group_id"
  task backfill_transfer_groups: :environment do
    paired = 0

    Space.find_each do |space|
      legs = space.transactions
                  .joins(:transaction_type)
                  .where(transaction_types: { kind: %w[transfer_in transfer_out] })
                  .where(transfer_group_id: nil)
                  .order(:created_at, :id)
                  .to_a

      legs.group_by { |t| [ t.transaction_date.to_s, t.amount.abs ] }.each_value do |group|
        outs = group.select { |t| t.transaction_type.kind == "transfer_out" }
        ins  = group.select { |t| t.transaction_type.kind == "transfer_in" }

        outs.zip(ins).each do |out_leg, in_leg|
          next unless out_leg && in_leg

          Transaction.where(id: [ out_leg.id, in_leg.id ]).update_all(transfer_group_id: SecureRandom.uuid)
          paired += 1
        end
      end
    end

    puts "Paired #{paired} transfer(s)"
  end
end

namespace :transactions do
  desc "Re-kind onboarding opening balances (orphan Transfer In legs) to initial_balance"
  task convert_onboarding_initial_balances: :environment do
    # The old onboarding recorded opening balances as partner-less transfer_in
    # rows with a recognisable description. Same sign, so no ledger adjustment.
    patterns = %w[en fr].map { |l| I18n.t("onboarding.account_setups.initial_balance_description", account_name: "%", locale: l) }
    converted = 0

    Space.find_each do |space|
      scope = space.transactions.joins(:transaction_type)
                   .where(transaction_types: { kind: "transfer_in" }, transfer_group_id: nil)
                   .where(patterns.map { "transactions.description LIKE ?" }.join(" OR "), *patterns)
      next if scope.none?

      type = FindOrCreateTransactionTypeService.new(
        space, I18n.t("transactions.initial_balance.type_name"), "initial_balance"
      ).call
      converted += scope.update_all(transaction_type_id: type.id, updated_at: Time.current)
    end

    Rails.logger.info "[transactions:convert_onboarding_initial_balances] converted #{converted} row(s)"
    puts "converted #{converted} opening-balance row(s)"
  end
end
