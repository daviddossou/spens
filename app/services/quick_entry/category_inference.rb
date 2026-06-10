# frozen_string_literal: true

module QuickEntry
  # Finds the taxonomy category implied by free text ("2000 zem" -> "moto_taxi"). Scans 1–3
  # word windows against the alias dictionary + taxonomy display names (EN+FR), keeping the
  # most specific (longest) hit. Returns a taxonomy key or nil — never invents a category.
  class CategoryInference
    MAX_NGRAM = 3

    def self.infer(text)
      new(text).infer
    end

    def initialize(text)
      @text = text.to_s
    end

    def infer
      best_key = nil
      best_score = [ 0, 0 ]
      learned = LearnedAlias.active_index

      tokens.each_index do |i|
        (1..MAX_NGRAM).each do |n|
          window = tokens[i, n]
          next unless window && window.size == n

          phrase = window.join(" ")
          # Learned aliases are the last resort, so they only ever fill a gap the built-ins miss.
          key = CategoryAliasMatcher.match(phrase) || TransactionTaxonomy.key_for_name(phrase) ||
                learned[CategoryText.normalize(phrase)]
          next unless key

          score = [ n, CategoryText.normalize(phrase).length ]
          if (score <=> best_score) == 1
            best_key = key
            best_score = score
          end
        end
      end

      best_key
    end

    private

    def tokens
      @tokens ||= @text.downcase.split(/[^[:alnum:]]+/).reject(&:blank?)
    end
  end
end
