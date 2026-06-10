# frozen_string_literal: true

module QuickEntry
  # Loads config/quick_entry_keywords.yml — the bilingual phrase lists behind the rules
  # parser. Memoised per process; call reload! after editing the YAML.
  class Keywords
    PATH = Rails.root.join("config", "quick_entry_keywords.yml")

    class << self
      def reload!
        @data = @numbers = nil
      end

      def data
        @data ||= YAML.load_file(PATH)
      end

      def kind(lang)    = section(lang, "kind")
      def date(lang)    = section(lang, "date")
      def weekdays(lang) = section(lang, "weekdays")
      def instruments(lang) = section(lang, "instruments")
      def transfer_prepositions(lang) = section(lang, "transfer_prepositions")
      def fee(lang)     = Array(for_lang(lang)["fee"])

      # { units:, tens:, scales: } with accent-stripped keys for matching.
      def numbers(lang)
        (@numbers ||= {})[lang.to_s] ||= build_numbers(lang)
      end

      private

      def for_lang(lang)
        data[lang.to_s] || data["en"]
      end

      def section(lang, key)
        for_lang(lang)[key] || {}
      end

      def build_numbers(lang)
        n = for_lang(lang)["numbers"] or return nil
        %w[units tens scales].each_with_object({}) do |group, out|
          out[group.to_sym] = translit_keys(n[group])
        end
      end

      def translit_keys(hash)
        (hash || {}).each_with_object({}) do |(word, value), out|
          out[I18n.transliterate(word.to_s).downcase.gsub(/[^a-z0-9-]/, "")] = value
        end
      end
    end
  end
end
