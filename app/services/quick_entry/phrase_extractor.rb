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
      le la les un une de des du pour et ou avec mon ma mes au aux sur ce cette chez paye achete depense pris ai
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

    # ALL noise-free tokens, not just the longest run — the material CategoryMemory stores
    # and matches by overlap ("Metro-Train Ticket 12.75 Wise" -> ["metro", "train", "ticket"]).
    # Unlike the residual run, alias-known words are KEPT: a memory exists precisely to let
    # the user's "train" override what the built-in dictionary thinks "train" means.
    def self.significant_tokens(text:, locale:, space:, exclude: [])
      new(text: text, locale: locale, space: space, exclude: exclude).significant_tokens
    end

    def significant_tokens
      tokens.select { |t| noise_free?(t) }.uniq
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

    def noise_free?(tok)
      tok.length >= 2 && !tok.match?(/\A\d/) && !ignored_tokens.include?(I18n.transliterate(tok))
    end

    def significant?(tok)
      noise_free?(tok) && CategoryAliasMatcher.match(tok).blank?
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
        *Keywords.months(lang).keys,
        *Keywords.extractor_stopwords(lang),
        *Keywords.instruments(lang).values.flatten,
        *Keywords.fee(lang),
        *Array(preps["from"]), *Array(preps["to"]),
        *@space.accounts.pluck(:name),
        *@space.transaction_types.pluck(:name),
        *@exclude,
        *STOPWORDS
      ].compact
    end
  end
end
