# frozen_string_literal: true

# Resolves a free-text phrase ("Carrefour", "Zem", "income tax") to a taxonomy subcategory key.
# Used to SUGGEST a category in the picker — it never silently rewrites what the user typed.
#
# The runtime dictionary is the "system" tier of learned_aliases (admin-editable, seeded by
# quick_entry:import_system_aliases). config/transaction_type_aliases.yml remains the seed
# source and the fallback while the table hasn't been imported (fresh dev/test DBs).
class CategoryAliasMatcher
  PATH = Rails.root.join("config", "transaction_type_aliases.yml")
  CACHE_TTL = 5.minutes

  class << self
    def reload!
      @index = @terms = @cached_at = nil
    end

    # normalized phrase => subcategory key
    def index
      refresh_cache
      @index
    end

    def match(value)
      return nil if value.blank?

      index[CategoryText.normalize(value)]
    end

    # Space-joined alias phrases for a subcategory key — fed to the picker so typing a
    # merchant/mode ("Carrefour", "Zem") surfaces the right category.
    def terms(key)
      refresh_cache
      @terms[key.to_s] || ""
    end

    # Every alias phrase across all keys — used for token-level dedup of learned candidates.
    def phrases
      refresh_cache
      @terms.values.flat_map(&:split)
    end

    private

    def refresh_cache
      return if @index && @cached_at && Time.current - @cached_at < CACHE_TTL

      rows = system_rows
      if rows.any?
        build_from_rows(rows)
      else
        build_from_yml
      end
      @cached_at = Time.current
    end

    def system_rows
      LearnedAlias.system_dictionary.active.pluck(:phrase, :display_phrase, :taxonomy_key)
    rescue ActiveRecord::StatementInvalid
      [] # table missing (rake tasks before migrate, asset builds): fall back to the YML
    end

    def build_from_rows(rows)
      @index = {}
      terms = Hash.new { |h, k| h[k] = [] }
      rows.each do |phrase, display, key|
        @index[phrase] = key
        terms[key] << (display.presence || phrase)
      end
      @terms = terms.transform_values { |list| list.join(" ") }
    end

    def build_from_yml
      raw = YAML.load_file(PATH)["aliases"] || {}
      @index = raw.each_with_object({}) do |(key, phrases), idx|
        Array(phrases).each { |phrase| idx[CategoryText.normalize(phrase)] = key.to_s }
      end
      @terms = raw.transform_keys(&:to_s).transform_values { |phrases| Array(phrases).join(" ") }
    end
  end
end
