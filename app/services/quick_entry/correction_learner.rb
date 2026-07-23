# frozen_string_literal: true

module QuickEntry
  # When a quick-entry transaction is edited, diff the user's saved values against the original
  # parse. A correction teaches the space's own vocabulary immediately (active — the user's
  # edit IS the approval, and their next utterance parses right without waiting for review)
  # AND feeds the global tier: a category correction becomes a global candidate LearnedAlias;
  # kind changes stay recorded on the attempt as signals for the offline miner.
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
      teach_kind(diff["kind"]) if diff.key?("kind")
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

    # Personal tier immediately + global candidate. Only when the corrected category is a
    # shared taxonomy node (never a custom type — the parser already matches those by name).
    #
    # The two tiers key on different phrases: the personal row re-teaches the word that LED to
    # the wrong guess ("carrefour" -> the user's pick, overriding the built-in), while the
    # global candidate keys on the residual word the dictionaries DON'T know yet (gap-fill).
    def teach_category(change)
      key = TransactionTaxonomy.key_for_name(change["to"]) or return
      residual = PhraseExtractor.call(text: @attempt.text, locale: @attempt.locale, space: @transaction.space)
      _, matched = CategoryInference.new(@attempt.text, space: @transaction.space).infer_with_phrase

      if (personal = matched || residual)
        LearnedAlias.personal_teach(space: @transaction.space, phrase: personal, taxonomy_key: key)
      end
      LearnedAlias.teach(phrase: residual, taxonomy_key: key, source: "edit_diff") if residual
    end

    # A structural kind correction teaches the space's own keyword immediately; the global
    # candidate stays the offline miner's job (it reads the recorded signal).
    def teach_kind(change)
      kind = kind_family(change["to"])
      return unless LearnedKeyword::KINDS.include?(kind)

      phrase = PhraseExtractor.call(
        text: @attempt.text, locale: @attempt.locale, space: @transaction.space,
        exclude: [ @transaction.debt&.name ].compact
      ) or return

      LearnedKeyword.personal_teach(space: @transaction.space, phrase: phrase, kind: kind)
    end
  end
end
