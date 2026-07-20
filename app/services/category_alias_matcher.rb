# frozen_string_literal: true

# Reads config/transaction_type_aliases.yml and resolves a free-text phrase
# ("Carrefour", "Zem", "income tax") to a taxonomy subcategory key. Used to SUGGEST a
# category in the picker — it never silently rewrites what the user typed.
class CategoryAliasMatcher
  PATH = Rails.root.join("config", "transaction_type_aliases.yml")

  class << self
    def reload!
      @index = @terms = nil
    end

    # normalized phrase => subcategory key
    def index
      @index ||= build_index
    end

    def match(value)
      return nil if value.blank?

      index[CategoryText.normalize(value)]
    end

    # Space-joined alias phrases for a subcategory key — fed to the picker so typing a
    # merchant/mode ("Carrefour", "Zem") surfaces the right category.
    def terms(key)
      all_terms[key.to_s] || ""
    end

    # Every alias phrase across all keys — used for token-level dedup of learned candidates.
    def phrases
      raw_aliases.values.flat_map { |p| Array(p) }
    end

    private

    def raw_aliases
      YAML.load_file(PATH)["aliases"] || {}
    end

    def build_index
      raw_aliases.each_with_object({}) do |(key, phrases), idx|
        Array(phrases).each { |phrase| idx[CategoryText.normalize(phrase)] = key.to_s }
      end
    end

    def all_terms
      @terms ||= raw_aliases.transform_keys(&:to_s).transform_values { |phrases| Array(phrases).join(" ") }
    end
  end
end
