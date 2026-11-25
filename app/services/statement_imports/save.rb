# frozen_string_literal: true

module StatementImports
  # "Enregistrer N transactions": every counted line becomes a transaction through the same
  # TransactionForm as a manual entry, so balances, budgets and debts move as usual. All or
  # nothing. Each expense/income line is also logged as a QuickEntryAttempt, so the user's
  # corrections teach the same learners as quick add.
  class Save
    Result = Data.define(:count, :invalid_lines, :categories) do
      def initialize(count:, invalid_lines:, categories: {})
        super
      end
    end

    def self.call(import)
      new(import).call
    end

    def initialize(import)
      @import = import
      @space = import.space
      @user = import.user
    end

    def call
      lines = @import.lines.proposed.where(decision: "pending").includes(:account, :counterpart_account).to_a
      invalid = []
      learning = []

      ActiveRecord::Base.transaction do
        lines.each do |line|
          form = TransactionForm.new(@space, line.payload.symbolize_keys)
          form.user = @user
          unless form.submit
            invalid << line
            next
          end

          tag(form.transaction)
          line.update!(decision: "accepted", created_transaction: form.transaction, final: line.payload)
          learning << [ form.transaction.id, log_attempt(line, form.transaction) ]
        end
        raise ActiveRecord::Rollback if invalid.any?

        @import.update!(status: "saved", saved_at: Time.current)
      end
      return Result.new(count: 0, invalid_lines: invalid) if invalid.any?


      learning.each do |transaction_id, attempt|
        QuickEntry::LearnTransactionJob.perform_later(transaction_id, ai_assist: attempt&.ai_used? || false, correction: attempt.present?)
      end
      Result.new(count: lines.size, invalid_lines: [], categories: category_stats(lines))
    end

    private

    # How saved lines got their category: tells whether people fix the "Other" fallback at all.
    # user_from_fallback = the user replaced "Other" by a real category.
    def category_stats(lines)
      categorised = lines.select(&:category_kind?)
      stats = categorised.map(&:category_source).tally.transform_keys { "category_#{_1 || "none"}" }
      stats.merge("category_user_from_fallback" => categorised.count { _1.category_source == "user" && _1.categorization && _1.categorization["proposed"].nil? })
    end

    # Every row the save created (transfer legs, fees) carries the import, so "Annuler" finds them.
    def tag(transaction)
      ids = [ transaction.id ]
      ids += @space.transactions.where(transfer_group_id: transaction.transfer_group_id).pluck(:id) if transaction.transfer_group_id
      ids += @space.transactions.where(fee_parent_id: ids).pluck(:id)
      @space.transactions.where(id: ids).update_all(statement_import_id: @import.id) # rubocop:disable Rails/SkipsModelValidations
    end

    def log_attempt(line, transaction)
      trace = line.categorization or return nil
      return nil unless line.category_kind? && trace["text"].present?

      # The proposal, not the final choice: the difference is what CorrectionLearner learns from.
      draft = trace["draft"].to_h.merge("kind" => line.kind, "amount" => line.amount.abs.to_s,
                                        "transaction_date" => line.occurred_on&.iso8601,
                                        "transaction_type_name" => trace["proposed"])
      QuickEntryAttempt.create!(space: @space, user: @user, created_transaction: transaction, text: trace["text"],
                                locale: trace["locale"], rules_draft: draft, ai_used: line.category_source == "ai",
                                ai_draft: trace["ai_draft"], source: "statement_import")
    end
  end
end
