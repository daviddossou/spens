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
    #   transfers: [ { from: Account, to: Account, amount:, prev: } ] }
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
      sums = pair_sums(@month) { |pair| !covered_pair?(pair) }
      prev = pair_sums(@month << 1) { |pair| sums.key?(pair) }

      accounts = @space.accounts.where(id: sums.keys.flatten.uniq).index_by(&:id)
      sums.map do |(from, to), amount|
        { from: accounts[from], to: accounts[to], amount: amount.round(2), prev: prev[[ from, to ]].to_f.round(2) }
      end.sort_by { |transfer| -transfer[:amount] }
    end

    def pair_sums(month)
      ins = transfer_legs(month, "transfer_in").index_by(&:transfer_group_id)

      sums = Hash.new(0)
      transfer_legs(month, "transfer_out").each do |leg|
        partner = ins[leg.transfer_group_id]
        next if partner.nil?

        pair = [ leg.account_id, partner.account_id ]
        sums[pair] += leg.amount.abs if yield(pair)
      end
      sums
    end

    def transfer_legs(month, kind)
      @space.transactions
            .where(transaction_date: month.all_month, fee_parent_id: nil)
            .joins(:transaction_type)
            .where(transaction_types: { kind: kind })
            .where.not(transfer_group_id: nil)
    end

    # A transfer is covered by an exact (from, to) budget pair, or by a
    # source-less line on its destination ("into this account from anywhere").
    def covered_pair?(pair)
      _from, to = pair
      covered_account_pairs.include?(pair) || covered_destinations.include?(to)
    end

    def covered_account_pairs
      @covered_account_pairs ||= transfer_entries
                                 .reject { |e| e.budget_item.from_account_id.nil? }
                                 .map { |e| [ e.budget_item.from_account_id, e.budget_item.to_account_id ] }
    end

    def covered_destinations
      @covered_destinations ||= transfer_entries
                                .select { |e| e.budget_item.from_account_id.nil? }
                                .map { |e| e.budget_item.to_account_id }
    end

    def transfer_entries
      @transfer_entries ||= entries.select { |e| e.kind == "transfer" }
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
