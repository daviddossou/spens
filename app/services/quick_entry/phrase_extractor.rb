# frozen_string_literal: true

module QuickEntry
  # The part of an utterance the rules couldn't account for: the longest contiguous run of
  # words that aren't numbers, known keywords, account names, stopwords, or already-known
  # aliases. It's what a learner keys on — the residual category word a correction reveals, or
  # the unknown verb the AI used to classify a kind. Capped at 3 words so CategoryInference
  # (1–3-grams) / detect_kind can match it back.
  #
  # `exclude:` drops extra names the caller has already resolved (e.g. the person / accounts the
  # AI named), so "j'ai dépanné Ali de 2k" yields "depanne", not "ali".
  class PhraseExtractor
    MAX_WORDS = 3

    # EN/FR filler dropped on top of the parser's own keywords.
    STOPWORDS = %w[
      the a an of for and or with my me you it at on in to from this that paid pay spent bought buy
      le la les un une de des du pour et ou avec mon ma mes au aux sur ce cette paye achete depense pris ai
    ].freeze

    def self.call(text:, locale:, space:, exclude: [])
      new(text: text, locale: locale, space: space, exclude: exclude).call
    end

    def initialize(text:, locale:, space:, exclude: [])
      @text = text.to_s
      @locale = locale
      @space = space
      @exclude = exclude
    end

    def call
      run = longest_significant_run
      run.empty? ? nil : run.join(" ")
    end

    private

    def longest_significant_run
      best = []
      current = []
      tokens.each do |tok|
        if significant?(tok)
          current << tok
          best = current.dup if current.size > best.size
        else
          current = []
        end
      end
      best.first(MAX_WORDS)
    end

    def tokens
      @tokens ||= @text.downcase.split(/[^[:alnum:]]+/).reject(&:blank?)
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
      lang = @locale.to_s.start_with?("fr") ? "fr" : "en"
      preps = Keywords.transfer_prepositions(lang)
      [
        *Keywords.kind(lang).values.flatten,
        *Keywords.date(lang).values.flatten,
        *Keywords.weekdays(lang).keys,
        *Keywords.instruments(lang).values.flatten,
        *Keywords.fee(lang),
        *Array(preps["from"]), *Array(preps["to"]),
        *@space.accounts.pluck(:name),
        *@exclude,
        *STOPWORDS
      ].compact
    end
  end
end
