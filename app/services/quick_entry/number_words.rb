# frozen_string_literal: true

module QuickEntry
  # Composes a spelled-out number EN + FR ("deux mille cinq cents" -> 2500) — what speech-to-
  # text emits when it doesn't digitise. Hyphens are kept for French multiplicatives
  # ("quatre-vingt-dix"). Returns nil when there are no number words.
  module NumberWords
    module_function

    def parse(text, lang)
      maps = Keywords.numbers(lang) or return nil
      compose(tokenize(text), maps)
    end

    def tokenize(text)
      text.to_s.split(/\s+/).map { |t| I18n.transliterate(t).downcase.gsub(/[^a-z0-9-]/, "") }.reject(&:empty?)
    end

    def compose(tokens, maps)
      units = maps[:units]; tens = maps[:tens]; scales = maps[:scales]
      total = 0
      current = 0
      matched = false

      tokens.each do |tok|
        if (v = units[tok] || tens[tok])
          current += v
          matched = true
        elsif (v = scales[tok])
          if v == 100
            current = (current.zero? ? 1 : current) * 100
          else
            current = 1 if current.zero?
            total += current * v
            current = 0
          end
          matched = true
        end
      end

      matched ? total + current : nil
    end
  end
end
