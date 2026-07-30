# frozen_string_literal: true

module Budgets
  # The month's money movements no budget line covers: income and expenses
  # summed per category, and account-to-account transfers summed per pair.
  # A budget line on a parent category covers its whole subtree, so only
  # truly unplanned categories surface here.
  class UnplannedActivityQuery
    def initialize(space:, month:)
      @space = space
      @month = month.beginning_of_month
    end

    # { income: { TransactionType => { amount:, prev: } },
    #   expense: { TransactionType => { amount:, prev: } },
    #   transfers: [ { from: Account, to: Account, amount: } ] }
    # Each list largest first. :prev is last month's activity on the same
    # category (0 when none) — a nonzero prev flags a recurring off-plan line.
    def call
      {
        income: category_sums("income"),
        expense: category_sums("expense"),
        transfers: transfer_sums
      }
    end

    private

    def category_sums(kind)
      sums = month_scope
             .joins(:transaction_type)
             .where(transaction_types: { kind: kind })
             .where.not(transaction_type_id: covered_type_ids(kind))
             .group(:transaction_type_id)
             .sum(:amount)

      prev = previous_month_sums(sums.keys)
      types = @space.transaction_types.where(id: sums.keys).index_by(&:id)
      sums.filter_map { |id, amount| [ types[id], { amount: amount.abs.round(2), prev: prev[id].to_f.abs.round(2) } ] if types[id] }
          .sort_by { |_, sums_for_type| -sums_for_type[:amount] }
          .to_h
    end

    def previous_month_sums(type_ids)
      return {} if type_ids.empty?

      @space.transactions
            .where(transaction_date: (@month << 1).all_month, fee_parent_id: nil)
            .where(transaction_type_id: type_ids)
            .group(:transaction_type_id)
            .sum(:amount)
    end

    def covered_type_ids(kind)
      entries.select { |e| e.kind == kind }
             .flat_map { |e| e.transaction_type&.subtree_ids }
             .compact
    end

    # Pair each transfer_out leg with its partner transfer_in leg to get the
    # (from, to) accounts, then keep the pairs no transfer budget line covers.
    def transfer_sums
      ins = transfer_legs("transfer_in").index_by(&:transfer_group_id)

      sums = Hash.new(0)
      transfer_legs("transfer_out").each do |leg|
        partner = ins[leg.transfer_group_id]
        next if partner.nil?

        pair = [ leg.account_id, partner.account_id ]
        sums[pair] += leg.amount.abs unless covered_account_pairs.include?(pair)
      end

      accounts = @space.accounts.where(id: sums.keys.flatten.uniq).index_by(&:id)
      sums.map { |(from, to), amount| { from: accounts[from], to: accounts[to], amount: amount.round(2) } }
          .sort_by { |transfer| -transfer[:amount] }
    end

    def transfer_legs(kind)
      month_scope
        .joins(:transaction_type)
        .where(transaction_types: { kind: kind })
        .where.not(transfer_group_id: nil)
    end

    def covered_account_pairs
      @covered_account_pairs ||= entries.select { |e| e.kind == "transfer" }
                                        .map { |e| [ e.budget_item.from_account_id, e.budget_item.to_account_id ] }
    end

    def entries
      @entries ||= @space.budget_entries.for_month(@month)
                         .includes(:transaction_type, :budget_item).to_a
    end

    def month_scope
      @space.transactions.where(transaction_date: @month.all_month, fee_parent_id: nil)
    end
  end
end
