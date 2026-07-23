# frozen_string_literal: true

module QuickEntry
  # Finds the taxonomy category implied by free text ("2000 zem" -> "moto_taxi"). Scans 1–3
  # word windows against the space's own learned vocabulary, then the alias dictionary +
  # taxonomy display names (EN+FR), keeping the most specific (longest) hit. Returns a
  # taxonomy key or nil — never invents a category.
  class CategoryInference
    MAX_NGRAM = 3

    def self.infer(text, space: nil)
      new(text, space: space).infer
    end

    def initialize(text, space: nil)
      @text = text.to_s
      @space = space
    end

    def infer
      infer_with_phrase.first
    end

    # [key, phrase]: the winning taxonomy key AND the text window that produced it — the word
    # the learners re-teach when the user corrects the category ("carrefour" -> their pick).
    def infer_with_phrase
      best_key = nil
      best_phrase = nil
      best_score = [ 0, 0 ]
      personal = LearnedAlias.personal_index(@space)
      learned = LearnedAlias.active_index

      tokens.each_index do |i|
        (1..MAX_NGRAM).each do |n|
          window = tokens[i, n]
          next unless window && window.size == n

          phrase = window.join(" ")
          # The space's own vocabulary outranks every built-in mapping ("carrefour" -> their
          # pick); global learned aliases stay the last resort and only ever fill a gap.
          key = personal[CategoryText.normalize(phrase)] ||
                CategoryAliasMatcher.match(phrase) || TransactionTaxonomy.key_for_name(phrase) ||
                learned[CategoryText.normalize(phrase)]
          next unless key

          score = [ n, CategoryText.normalize(phrase).length ]
          if (score <=> best_score) == 1
            best_key = key
            best_phrase = phrase
            best_score = score
          end
        end
      end

      [ best_key, best_phrase ]
    end

    private

    def tokens
      @tokens ||= @text.downcase.split(/[^[:alnum:]]+/).reject(&:blank?)
    end
  end
end
