# frozen_string_literal: true

module QuickEntry
  # When a quick-entry transaction is edited, diff the user's saved values against the original
  # parse. A category correction becomes a global LearnedAlias (so the rules catch it next time);
  # other field changes are recorded on the attempt as signals for the offline miner.
  class CorrectionLearner
    def self.learn(transaction)
      new(transaction).learn
    rescue StandardError => e
      Rails.logger.warn("quick-entry correction learning failed: #{e.message}")
      nil
    end

    def initialize(transaction)
      @transaction = transaction
      @attempt = QuickEntryAttempt.find_by(transaction_id: transaction.id)
    end

    def learn
      return unless @attempt

      @transaction.reload
      diff = compute_diff
      return if diff.empty?

      @attempt.update!(outcome: "edited", corrections: diff)
      teach_category(diff["transaction_type_name"]) if diff.key?("transaction_type_name")
    end

    private

    def compute_diff
      draft = @attempt.rules_draft
      {
        "transaction_type_name" => category_change(draft["transaction_type_name"]),
        "amount" => amount_change(draft["amount"]),
        "kind" => kind_change(draft["kind"]),
        "transaction_date" => date_change(draft["transaction_date"])
      }.compact
    end

    # A blank original is a signal too — the parser found no category and the user picked one
    # on the fallback form — but only for income/expense (transfers/debt legitimately have no
    # draft category, so there's nothing to compare).
    def category_change(original)
      current = @transaction.transaction_type.name
      if original.blank?
        return nil unless %w[income expense].include?(@transaction.transaction_type.kind)

        return { "from" => nil, "to" => current }
      end

      return nil if CategoryText.normalize(original) == CategoryText.normalize(current)

      { "from" => original, "to" => current }
    end

    def amount_change(original)
      return nil if original.blank?

      current = @transaction.amount.abs
      original.to_f == current.to_f ? nil : { "from" => original, "to" => current }
    end

    def kind_change(original)
      current = @transaction.transaction_type.kind
      return nil if kind_family(original) == kind_family(current)

      { "from" => original, "to" => current }
    end

    def date_change(original)
      current = @transaction.transaction_date.iso8601
      original.to_s == current ? nil : { "from" => original, "to" => current }
    end

    # transfer_in/transfer_out both come from a "transfer" draft — not a real correction.
    def kind_family(kind)
      kind.to_s.start_with?("transfer") ? "transfer" : kind.to_s
    end

    # Only learn when the corrected category is a shared taxonomy node (never a custom type).
    def teach_category(change)
      key = TransactionTaxonomy.key_for_name(change["to"]) or return
      phrase = PhraseExtractor.call(text: @attempt.text, locale: @attempt.locale, space: @transaction.space) or return

      LearnedAlias.teach(phrase: phrase, taxonomy_key: key, source: "edit_diff")
    end
  end
end
