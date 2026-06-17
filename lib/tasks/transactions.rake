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
