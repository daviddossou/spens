# frozen_string_literal: true

# Category tree (Parent -> Subcategory, two flat levels). Keys are stable and
# locale-independent; display names are bilingual.
#
# Runtime source is the taxonomy_nodes table (admin-editable, seeded by
# taxonomy:import_nodes). config/transaction_taxonomy.yml remains the seed source and
# the fallback while the table hasn't been imported (fresh dev/test DBs).
class TransactionTaxonomy
  PATH = Rails.root.join("config", "transaction_taxonomy.yml")
  KINDS = %w[expense income].freeze
  CACHE_TTL = 5.minutes

  class << self
    def reload!
      @data = @nodes = @name_index = @cached_at = nil
    end

    def data
      refresh_cache
      @data
    end

    # key => { "en" =>, "fr" =>, "kind" =>, "parent" => (nil for a parent category) }
    def nodes
      refresh_cache
      @nodes
    end

    def node(key)
      nodes[key.to_s]
    end

    def exists?(key)
      nodes.key?(key.to_s)
    end

    def name(key, locale = I18n.locale)
      n = node(key) or return nil
      n[locale.to_s] || n["en"]
    end

    def kind_of(key)
      node(key)&.fetch("kind", nil)
    end

    def parent_key(key)
      node(key)&.fetch("parent", nil)
    end

    def parent?(key)
      exists?(key) && parent_key(key).nil?
    end

    def parent_keys(kind = nil)
      kinds(kind).flat_map { |k| (data[k] || {}).keys }
    end

    def child_keys(parent_key)
      (parent_node(parent_key)&.fetch("children", nil) || {}).keys
    end

    # Parent under which a free-text / unmatched category is filed.
    def default_parent_key(kind)
      kind.to_s == "income" ? "other_income" : "other_expense"
    end

    # Resolve a (possibly emoji-prefixed / accented) display name back to its stable key.
    def key_for_name(value)
      name_index[CategoryText.normalize(value)]
    end

    private

    def refresh_cache
      return if @data && @cached_at && Time.current - @cached_at < CACHE_TTL

      rows = db_rows
      @data = rows.any? ? build_from_rows(rows) : YAML.load_file(PATH)
      @nodes = build_nodes
      @name_index = nil
      @cached_at = Time.current
    end

    def db_rows
      TaxonomyNode.active.ordered.pluck(:key, :kind, :parent_key, :name_en, :name_fr)
    rescue ActiveRecord::StatementInvalid
      [] # table missing (rake tasks before migrate, asset builds): fall back to the YML
    end

    # Rebuild the nested YML shape from flat rows; insertion order = position, so
    # parent_keys / child_keys keep the admin-defined ordering.
    def build_from_rows(rows)
      data = KINDS.index_with { {} }
      rows.each do |key, kind, parent_key, en, fr|
        next unless parent_key.nil? && data.key?(kind)

        data[kind][key] = { "en" => en, "fr" => fr, "children" => {} }
      end
      rows.each do |key, kind, parent_key, en, fr|
        parent = parent_key && data.dig(kind, parent_key)
        parent["children"][key] = { "en" => en, "fr" => fr } if parent
      end
      data
    end

    def kinds(kind)
      kind ? [ kind.to_s ] : KINDS
    end

    def parent_node(parent_key)
      KINDS.each do |k|
        found = (data[k] || {})[parent_key.to_s]
        return found if found
      end
      nil
    end

    def name_index
      @name_index ||= nodes.each_with_object({}) do |(key, n), idx|
        idx[CategoryText.normalize(n["en"])] = key
        idx[CategoryText.normalize(n["fr"])] = key
      end
    end

    def build_nodes
      {}.tap do |result|
        KINDS.each do |kind|
          (@data[kind] || {}).each do |pkey, pnode|
            result[pkey.to_s] = { "en" => pnode["en"], "fr" => pnode["fr"], "kind" => kind, "parent" => nil }
            (pnode["children"] || {}).each do |ckey, cnode|
              result[ckey.to_s] = { "en" => cnode["en"], "fr" => cnode["fr"], "kind" => kind, "parent" => pkey.to_s }
            end
          end
        end
      end
    end
  end
end
