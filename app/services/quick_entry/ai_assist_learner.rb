# frozen_string_literal: true

module QuickEntry
  # After the AI rescued an utterance the rules couldn't, capture what it taught us as *candidate*
  # vocabulary, so the rules can handle the next one AI-free. Two things grow:
  #   • the category word    -> a LearnedAlias   (phrase -> taxonomy key, for expense/income)
  #   • the structural verb  -> a LearnedKeyword (phrase -> transfer/debt, the kind the rules missed)
  # Both stay candidates (not yet consulted) until a human approves them in the dashboard, so one
  # AI guess can't pollute the global dictionaries.
  class AiAssistLearner
    DIRECTION_KIND = { "lent" => "debt_out", "borrowed" => "debt_in" }.freeze

    def self.learn(attempt)
      new(attempt).learn
    rescue StandardError => e
      Rails.logger.warn("quick-entry AI-assist learning failed: #{e.message}")
      nil
    end

    def initialize(attempt)
      @attempt = attempt
    end

    def learn
      ai = @attempt.ai_draft or return
      teach_alias(ai)
      teach_keyword(ai)
    end

    private

    # expense/income: the word the AI keyed the category on -> the space's own alias (active —
    # the auto-created transaction the user keeps is an implicit validation, and a later edit
    # re-teaches over it) + a global candidate for the review queue.
    def teach_alias(ai)
      phrase = ai["phrase"].presence or return
      key = ai["category_key"].presence or return

      LearnedAlias.personal_teach(space: @attempt.space, phrase: phrase, taxonomy_key: key)
      LearnedAlias.teach(phrase: phrase, taxonomy_key: key, source: "ai")
    end

    # transfer/debt: the verb that signalled a kind the rules read as a plain expense -> a
    # candidate kind keyword. The phrase is extracted deterministically (not trusted from the
    # model), excluding the person/accounts the AI already named.
    def teach_keyword(ai)
      kind = structural_kind(ai) or return
      phrase = kind_phrase(ai) or return

      LearnedKeyword.personal_teach(space: @attempt.space, phrase: phrase, kind: kind)
      LearnedKeyword.teach(phrase: phrase, kind: kind, source: "ai")
    end

    def structural_kind(ai)
      case ai["kind"]
      when "transfer"                    then "transfer"
      when "debt", "debt_in", "debt_out" then DIRECTION_KIND[ai["direction"].to_s]
      end
    end

    def kind_phrase(ai)
      PhraseExtractor.call(
        text: @attempt.text, locale: @attempt.locale, space: @attempt.space,
        exclude: [ ai["person"], ai["from_account"], ai["to_account"] ].compact
      )
    end
  end
end
