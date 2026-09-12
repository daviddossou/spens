# frozen_string_literal: true

module QuickEntry
  # Turns the raw note the user typed ("j'ai payé 19 la pharmacie hier sur trade republic")
  # into a short line worth showing under a movement ("Pharmacie"): amounts, currency,
  # the account name, date words and transaction verbs are dropped, the rest is kept as typed.
  class NoteLabel
    LANGS = %w[en fr].freeze
    MAX_LENGTH = 60

    AMOUNT = /\A[€$£]?\d[\d.,]*(?:k|m)?[€$£]?\z/i
    NUMERIC_DATE = %r{\A\d{1,2}[/.-]\d{1,2}(?:[/.-]\d{2,4})?\z}
    CURRENCY = %w[€ $ £ eur euro euros fcfa cfa xof usd gbp f].freeze
    EDGE_FILLERS = %w[
      le la les l un une de des du d pour et ou a au aux chez en sur avec mon ma mes je jai on nous
      the an of for at to with my in from i ive we
    ].freeze

    def self.call(note, account_name: nil)
      new(note, account_name: account_name).call
    end

    def initialize(note, account_name: nil)
      @note = note.to_s
      @account_name = account_name
    end

    def call
      return nil if @note.strip.empty?

      tokens = @note.split(/\s+/).map { |word| [ word, normalize(word) ] }
      tokens = drop_phrases(tokens)
      tokens = tokens.reject { |_, norm| noise?(norm) }
      tokens = trim_edges(tokens)
      finish(tokens.map(&:first).join(" "))
    end

    private

    def normalize(word)
      I18n.transliterate(word).downcase.gsub(/[^a-z0-9€$£.,\/-]/, "")
    end

    # Multi-word phrases (account name, "day before yesterday", "paid back"…), longest first.
    def drop_phrases(tokens)
      phrases.each do |phrase|
        next if phrase.length > tokens.length

        idx = 0
        while idx <= tokens.length - phrase.length
          if tokens[idx, phrase.length].map(&:last) == phrase
            tokens.slice!(idx, phrase.length)
          else
            idx += 1
          end
        end
      end
      tokens
    end

    def phrases
      @phrases ||= (to_phrases([ @account_name ].compact) + self.class.keyword_phrases).uniq.sort_by { |p| -p.length }
    end

    def to_phrases(words)
      words.map { |w| w.to_s.split(/\s+/).map { |part| normalize(part) }.reject(&:empty?) }.reject(&:empty?)
    end

    def self.keyword_phrases
      @keyword_phrases ||= begin
        words = LANGS.flat_map do |lang|
          Keywords.kind(lang).values.flatten + Keywords.date(lang).values.flatten +
            Keywords.weekdays(lang).keys + Keywords.months(lang).keys +
            Keywords.extractor_stopwords(lang) + Keywords.fee(lang)
        end
        new(nil).send(:to_phrases, words + CURRENCY)
      end
    end

    def noise?(norm)
      norm.empty? || norm.match?(AMOUNT) || norm.match?(NUMERIC_DATE)
    end

    def trim_edges(tokens)
      filler = ->(pair) { EDGE_FILLERS.include?(pair.last.sub(/\A[^a-z0-9]+|[^a-z0-9]+\z/, "")) }
      tokens = tokens.drop_while(&filler)
      tokens.reverse.drop_while(&filler).reverse
    end

    def finish(text)
      text = text.gsub(/\A[[:punct:][:space:]]+|[[:punct:][:space:]]+\z/, "").squeeze(" ")
      return nil if text.empty?

      text = text[0, MAX_LENGTH].strip if text.length > MAX_LENGTH
      text[0].upcase + text[1..]
    end
  end
end
