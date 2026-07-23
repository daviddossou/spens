# frozen_string_literal: true

module QuickEntry
  # Rules-first, deterministic brain: turns one utterance into a Draft, no AI. Built for
  # transcribed speech (spelled-out numbers, little punctuation), EN + FR.
  class Parser
    # "a"/"an" are excluded — "a" is also the French "to" preposition (à).
    ARTICLES = %w[le la les l un une mon ma mes ton ta tes son sa ses notre nos votre vos my the].freeze
    # Words tolerated between a fee amount and its keyword ("700 comme frais", "fee of 700").
    FEE_FILLERS = %w[de du d of as comme en pour].freeze

    def self.parse(text, space:, locale: I18n.locale)
      new(text, space: space, locale: locale).parse
    end

    def initialize(text, space:, locale:)
      @text = text.to_s.strip
      @space = space
      @lang = detect_language(locale)
    end

    def parse
      @kind = detect_kind
      detect_date # first: date digits are blanked out before amount detection reads the text
      @amount = detect_amount
      @fee = detect_fee(@amount)

      transfer? ? transfer_draft : standard_draft
    end

    private

    def transfer?
      @kind == "transfer"
    end

    def transfer_draft
      accounts = transfer_accounts

      unresolved = []
      unresolved << :amount if @amount.blank?
      unresolved << :from_account if accounts[:from].blank?
      unresolved << :to_account if accounts[:to].blank?

      Draft.new(
        kind: "transfer",
        amount: @amount,
        from_account_name: accounts[:from],
        to_account_name: accounts[:to],
        fee_amount: @fee,
        transaction_date: detect_date,
        description: @text.presence,
        unresolved: unresolved
      )
    end

    def standard_draft
      type_name, kind = resolve_category(@kind)

      unresolved = []
      unresolved << :amount if @amount.blank?
      unresolved << :category if type_name.blank?

      Draft.new(
        kind: kind,
        amount: @amount,
        account_name: detect_account,
        transaction_type_name: type_name,
        fee_amount: @fee,
        transaction_date: detect_date,
        description: @text.presence,
        debt_id: nil,
        unresolved: unresolved
      )
    end

    # --- text helpers -------------------------------------------------------

    def normalized
      @normalized ||= CategoryText.normalize(@text)
    end

    # Transliterated + downcased, keeping word boundaries (CategoryText.normalize strips them)
    # so prepositions and number runs can be read positionally.
    def loose_text
      @loose_text ||= I18n.transliterate(@text).downcase
    end

    def loose_tokens
      @loose_tokens ||= loose_text.split(/[^a-z0-9-]+/).reject(&:empty?)
    end

    def translit(str)
      I18n.transliterate(str.to_s).downcase
    end

    def match_any?(phrases)
      Array(phrases).any? { |phrase| normalized.include?(CategoryText.normalize(phrase)) }
    end

    # --- language -----------------------------------------------------------

    # Parse in the language of the utterance, not just the UI: score each language's
    # distinctive keywords and pick the winner, falling back to the session locale on a tie.
    def detect_language(locale)
      hint = locale.to_s.start_with?("fr") ? "fr" : "en"
      fr = language_score("fr")
      en = language_score("en")
      return hint if fr == en

      fr > en ? "fr" : "en"
    end

    def language_score(lang)
      language_signals(lang).count { |phrase| signal_present?(phrase, loose_tokens) }
    end

    def language_signals(lang)
      [
        *Keywords.kind(lang).values.flatten,
        *Keywords.fee(lang),
        *Keywords.date(lang).values.flatten,
        *Keywords.instruments(lang).values.flatten,
        *Keywords.weekdays(lang).keys
      ]
    end

    # A signal matches when its significant words (len >= 3, skipping ambiguous short words
    # like "de"/"to") all appear as whole tokens.
    def signal_present?(phrase, toks)
      parts = translit(phrase).split(/[^a-z0-9-]+/).select { |p| p.length >= 3 }
      parts.any? && parts.all? { |p| toks.include?(p) }
    end

    # --- kind ---------------------------------------------------------------

    def detect_kind
      kw = Keywords.kind(@lang)
      detected =
        if match_any?(kw["debt_lent"]) then "debt_out"
        elsif match_any?(kw["debt_borrowed"]) then "debt_in"
        elsif match_any?(kw["transfer"]) then "transfer"
        elsif match_any?(kw["income"]) then "income"
        else learned_kind
        end

      @explicit_kind = !detected.nil?
      detected || "expense"
    end

    # Learned verbs (LearnedKeyword), consulted only after the built-in sets miss, so they fill
    # a gap — never shadow a built-in. The space's own keywords (active on first correction)
    # come before the human-approved global ones.
    def learned_kind
      LearnedKeyword.personal_index(@space).find { |phrase, _| normalized.include?(phrase) }&.last ||
        LearnedKeyword.active_index.find { |phrase, _| normalized.include?(phrase) }&.last
    end

    # --- amount -------------------------------------------------------------

    def detect_amount
      amount_in(amount_source)
    end

    # The utterance with date substrings blanked, so "le 16 juin" or "16/06" can never be
    # read as the amount. Falls back to the transliterated text when no date matched.
    def amount_source
      @amount_source || loose_text
    end

    def ignore_for_amount(str)
      @amount_source = amount_source.sub(str, " ")
    end

    def amount_in(str)
      suffix_amount(str) || digit_amount(str) || NumberWords.parse(str, @lang)
    end

    # "5k", "2.5k", "1m"
    def suffix_amount(str)
      m = str.match(/(\d+(?:[.,]\d+)?)\s*(k|m)\b/i) or return nil
      m[1].tr(",", ".").to_f * (m[2].casecmp("m").zero? ? 1_000_000 : 1_000)
    end

    def digit_amount(str)
      m = str.match(/\d[\d .,]*\d|\d/) or return nil
      normalize_number(m[0])
    end

    # "2 000"/"2.000"/"2,000" -> 2000 (thousands separators); "12.50" -> 12.5 (decimal).
    def normalize_number(str)
      s = str.gsub(/\s/, "")
      if s.match?(/\A\d+[.,]\d{1,2}\z/)
        s.tr(",", ".").to_f
      else
        s.gsub(/[.,]/, "").to_f
      end
    end

    # --- fee ----------------------------------------------------------------

    # The number run nearest a fee keyword ("…et 700 de frais", "with 500 fee"), ignored when
    # it just echoes the main amount.
    def detect_fee(main_amount)
      fee_words = Keywords.fee(@lang).map { |w| translit(w) }
      return nil if fee_words.empty?

      toks = amount_source.split(/[^a-z0-9-]+/).reject(&:empty?)
      idx = toks.index { |t| fee_words.include?(t) }
      return nil unless idx

      run = [ number_run_before(toks, idx), number_run_after(toks, idx) ].max_by(&:size)
      return nil if run.empty?

      fee = amount_in(run.join(" "))
      fee if fee&.positive? && fee != main_amount
    end

    def number_run_before(toks, idx)
      i = idx - 1
      i -= 1 if i >= 0 && FEE_FILLERS.include?(toks[i])
      run = []
      while i >= 0 && number_token?(toks[i])
        run.unshift(toks[i])
        i -= 1
      end
      run
    end

    def number_run_after(toks, idx)
      i = idx + 1
      i += 1 if i < toks.size && FEE_FILLERS.include?(toks[i])
      run = []
      while i < toks.size && number_token?(toks[i])
        run << toks[i]
        i += 1
      end
      run
    end

    def number_token?(tok)
      return true if tok.match?(/\A\d[\d.,]*(?:k|m)?\z/i)

      tok.length > 1 && number_word?(tok)
    end

    def number_word?(tok)
      maps = Keywords.numbers(@lang) or return false
      maps[:units].key?(tok) || maps[:tens].key?(tok) || maps[:scales].key?(tok)
    end

    # --- date ---------------------------------------------------------------

    def detect_date
      @date ||= absolute_date || relative_date || Date.current
    end

    def relative_date
      dates = Keywords.date(@lang)
      # Check the longer phrase first: "day before yesterday" / "avant-hier" contain "yesterday" / "hier".
      return Date.current - 2 if match_any?(dates["day_before_yesterday"])
      return Date.current - 1 if match_any?(dates["yesterday"])

      days = relative_days_ago
      return Date.current - days if days

      weekday_date
    end

    # "3 days ago" / "il y a 3 jours" / "2 weeks ago" / "il y a 2 semaines" -> days back.
    def relative_days_ago
      if (m = @text.match(/(\d+)\s*(?:days?|jours?)\s*ago|il y a\s*(\d+)\s*jours?/i))
        n = (m[1] || m[2]).to_i
        ignore_for_amount(translit(m[0]))
        return n if n.positive?
      end
      if (m = @text.match(/(\d+)\s*(?:weeks?|semaines?)\s*ago|il y a\s*(\d+)\s*semaines?/i))
        n = (m[1] || m[2]).to_i
        ignore_for_amount(translit(m[0]))
        return n * 7 if n.positive?
      end
      nil
    end

    # "16/06", "16-06-2026", "le 16 juin 2026", "june 16", "on june 16 2026".
    def absolute_date
      numeric_date || named_month_date
    end

    def numeric_date
      m = loose_text.match(%r{\b(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b}) or return nil
      day, month = order_day_month(m[1].to_i, m[2].to_i)
      return nil unless day

      date = build_date(m[3], month, day) or return nil
      ignore_for_amount(m[0])
      date
    end

    # FR reads d/m, EN m/d; an impossible reading falls back to the other order.
    def order_day_month(a, b)
      guess = @lang == "en" ? [ b, a ] : [ a, b ]
      return guess if valid_day_month?(*guess)

      swapped = guess.reverse
      valid_day_month?(*swapped) ? swapped : []
    end

    def valid_day_month?(day, month)
      day.between?(1, 31) && month.between?(1, 12)
    end

    def named_month_date
      months = Keywords.months(@lang)
      return nil if months.blank?

      pattern = months.keys.sort_by { |k| -k.length }.join("|")
      m = loose_text.match(/(?:\ble\s+)?\b(?:(\d{1,2})(?:er|st|nd|rd|th)?\s+)?(#{pattern})\b\.?,?\s*(?:(\d{1,2})(?:st|nd|rd|th)?\b)?,?\s*(\d{4})?/)
      return nil unless m

      day = (m[1] || m[3]).to_i
      return nil unless day.between?(1, 31)

      date = build_date(m[4], months[m[2]], day) or return nil
      ignore_for_amount(m[0])
      date
    end

    def build_date(year_str, month, day)
      year = year_str.blank? ? Date.current.year : expand_year(year_str.to_i)
      Date.new(year, month, day)
    rescue Date::Error
      nil
    end

    def expand_year(year) = year < 100 ? 2000 + year : year

    # A named weekday ("monday"/"lundi") -> its most recent past occurrence (today if it matches).
    def weekday_date
      weekdays = Keywords.weekdays(@lang)
      return nil if weekdays.blank?

      hit = weekdays.find { |name, _| loose_tokens.include?(translit(name)) }
      return nil unless hit

      Date.current - ((Date.current.cwday - hit[1]) % 7)
    end

    # --- account ------------------------------------------------------------

    def detect_account
      names = @space.accounts.pluck(:name)

      direct = names.find do |name|
        norm = CategoryText.normalize(name)
        norm.length >= 3 && normalized.include?(norm)
      end
      return direct if direct

      Keywords.instruments(@lang).each_value do |phrases|
        next unless match_any?(phrases)

        hit = names.find { |name| phrases.any? { |p| CategoryText.normalize(name).include?(CategoryText.normalize(p)) } }
        return hit if hit
      end

      nil
    end

    # Source/destination of a transfer, each resolved to an existing account named after a
    # "from"/"to" preposition. nil when not named or unknown — so we never auto-create onto an
    # account the user hasn't set up.
    def transfer_accounts
      preps = Keywords.transfer_prepositions(@lang)
      { from: account_after(Array(preps["from"])), to: account_after(Array(preps["to"])) }
    end

    def account_after(prepositions)
      return nil if prepositions.empty?

      markers = prepositions.map { |p| translit(p) }
      toks = loose_tokens
      @space.accounts.pluck(:name).find do |name|
        pos = subsequence_index(toks, account_tokens(name))
        pos && markers.include?(marker_before_token(toks, pos))
      end
    end

    # Transliterated significant words of an account name, so "🏦 Orabank" -> ["orabank"].
    def account_tokens(name)
      translit(name).split(/[^a-z0-9-]+/).reject(&:empty?)
    end

    def subsequence_index(toks, sub)
      return nil if sub.empty? || sub.size > toks.size

      (0..toks.size - sub.size).find { |i| toks[i, sub.size] == sub }
    end

    def marker_before_token(toks, pos)
      j = pos - 1
      j -= 1 while j >= 0 && ARTICLES.include?(toks[j])
      j >= 0 ? toks[j] : nil
    end

    # --- category -----------------------------------------------------------

    def resolve_category(kind)
      name, type_kind = custom_type_match
      if name && (type_kind == kind || !@explicit_kind)
        return [ name, type_kind ]
      end

      key = CategoryInference.infer(@text, space: @space)
      return [ nil, kind ] unless key

      cat_kind = TransactionTaxonomy.kind_of(key)
      # The category can settle the kind when no kind keyword fired (e.g. "rental income").
      kind = cat_kind if cat_kind && cat_kind != kind && !@explicit_kind
      return [ nil, kind ] unless cat_kind == kind

      [ TransactionTaxonomy.name(key, @lang), kind ]
    end

    # A user-created category spoken directly ("contribution" -> "Contribution DD"): the user's
    # own vocabulary beats taxonomy inference. Only truly custom types (no template_key) — the
    # taxonomy-templated ones are already covered by CategoryInference. Longest match wins.
    def custom_type_match
      @space.transaction_types.where(template_key: nil, kind: %w[income expense]).pluck(:name, :kind)
            .filter_map { |name, type_kind| (len = custom_match_length(name)) && [ len, name, type_kind ] }
            .max_by(&:first)&.drop(1)
    end

    # Full normalized name in the utterance, or any distinctive (>= 4 chars) word of the name
    # spoken as a whole token. Returns the matched length, nil when no match.
    def custom_match_length(name)
      norm = CategoryText.normalize(name)
      return norm.length if norm.length >= 3 && normalized.include?(norm)

      account_tokens(name).find { |t| t.length >= 4 && loose_tokens.include?(t) }&.length
    end
  end
end
