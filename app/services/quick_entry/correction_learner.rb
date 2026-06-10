# frozen_string_literal: true

module QuickEntry
  # When a quick-entry transaction is edited, diff the user's saved values against the original
  # parse. A category correction becomes a global LearnedAlias (so the rules catch it next time);
  # other field changes are recorded on the attempt as signals for the offline miner.
  class CorrectionLearner
    # EN/FR filler the residual-phrase extraction drops on top of the parser's own keywords.
    STOPWORDS = %w[
      the a an of for and or with my me you it at on in to from this that paid pay spent bought buy
      le la les un une de des du pour et ou avec mon ma mes au aux sur ce cette paye achete depense pris
    ].freeze

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

    # Skipped when the draft had no category (transfers/debt): there's nothing to compare.
    def category_change(original)
      return nil if original.blank?

      current = @transaction.transaction_type.name
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
      phrase = candidate_phrase or return

      LearnedAlias.teach(phrase: phrase, taxonomy_key: key, source: "edit_diff")
    end

    # The part of the utterance the rules couldn't categorise: the longest contiguous run of
    # words that aren't numbers, known keywords, account names, stopwords, or already-known
    # aliases. Capped at 3 words so CategoryInference (1–3-grams) can match it back.
    def candidate_phrase
      run = longest_significant_run
      run.empty? ? nil : run.join(" ")
    end

    def longest_significant_run
      best = []
      current = []
      utterance_tokens.each do |tok|
        if significant?(tok)
          current << tok
          best = current.dup if current.size > best.size
        else
          current = []
        end
      end
      best.first(3)
    end

    def utterance_tokens
      @utterance_tokens ||= @attempt.text.to_s.downcase.split(/[^[:alnum:]]+/).reject(&:blank?)
    end

    def significant?(tok)
      return false if tok.length < 2 || tok.match?(/\A\d/)
      return false if ignored_tokens.include?(I18n.transliterate(tok))

      CategoryAliasMatcher.match(tok).blank?
    end

    def ignored_tokens
      @ignored_tokens ||= keyword_phrases.flat_map { |p| I18n.transliterate(p).downcase.split(/[^a-z0-9-]+/) }
                                         .reject(&:empty?).to_set
    end

    def keyword_phrases
      lang = @attempt.locale.to_s.start_with?("fr") ? "fr" : "en"
      preps = Keywords.transfer_prepositions(lang)
      [
        *Keywords.kind(lang).values.flatten,
        *Keywords.date(lang).values.flatten,
        *Keywords.weekdays(lang).keys,
        *Keywords.instruments(lang).values.flatten,
        *Keywords.fee(lang),
        *Array(preps["from"]), *Array(preps["to"]),
        *@transaction.space.accounts.pluck(:name),
        *STOPWORDS
      ]
    end
  end
end
