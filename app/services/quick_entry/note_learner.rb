# frozen_string_literal: true

module QuickEntry
  # Learns the space's own vocabulary from the human note. When a saved transaction pairs a
  # note ("chez Diallo") with a taxonomy category (Restaurant), the signal phrase becomes a
  # personal alias — so the next time that phrase is typed (form or quick entry), the right
  # category comes up first, AI-free. When the word is globally UNKNOWN it also feeds the admin
  # review queue as a candidate (gap-fill only — a known word like "carrefour" stays a personal
  # preference and never reaches the queue).
  #
  # The note is the human phrase now (the system-composed text lives in `description` and
  # carries no learning signal), so this learner reads `note`, not `description`.
  class NoteLearner
    def self.learn(transaction, locale: I18n.locale)
      new(transaction, locale: locale).learn
    rescue StandardError => e
      Rails.logger.warn("note learning failed: #{e.message}")
      nil
    end

    def initialize(transaction, locale:)
      @transaction = transaction
      @locale = locale
    end

    def learn
      return if @transaction.note.blank?

      type = @transaction.transaction_type
      return unless %w[income expense].include?(type.kind)

      key = type.template_key.presence || TransactionTaxonomy.key_for_name(type.name) or return
      phrase = signal_phrase or return

      LearnedAlias.personal_teach(space: @transaction.space, phrase: phrase, taxonomy_key: key)
      LearnedAlias.teach(phrase: phrase, taxonomy_key: key, source: "note")

      tokens = PhraseExtractor.significant_tokens(text: @transaction.note, locale: @locale,
                                                  space: @transaction.space)
      CategoryMemory.remember(space: @transaction.space, tokens: tokens, taxonomy_key: key)
    end

    private

    # The word carrying the pairing: the one the dictionaries already key on ("carrefour" —
    # so the user's pick can override the default), else the residual word nobody knows yet.
    def signal_phrase
      _, matched = CategoryInference.new(@transaction.note, space: @transaction.space).infer_with_phrase
      matched || PhraseExtractor.call(text: @transaction.note, locale: @locale, space: @transaction.space)
    end
  end
end
