# frozen_string_literal: true

module Taxonomy
  # Brings taxonomy_nodes in line with the YML — what `taxonomy:import_nodes` refuses to do,
  # since it only creates missing keys so admin edits survive. Renames, moves and retires;
  # never changes a key (immutable) and never destroys (a dropped node is deactivated, so
  # existing template_key references keep resolving). Idempotent; parents written first.
  class SyncNodes
    Result = Struct.new(:created, :renamed, :moved, :deactivated, keyword_init: true)

    # `data` bypasses the file: specs pass a literal tree.
    def initialize(data: nil, path: TransactionTaxonomy::PATH)
      @data = data || YAML.load_file(path)
      @result = Result.new(created: 0, renamed: 0, moved: 0, deactivated: 0)
    end

    def call
      ActiveRecord::Base.transaction do
        each_node(parents_only: true) { |*args| upsert(*args) }
        each_node(parents_only: false) { |*args| upsert(*args) }
        deactivate_dropped
      end
      TransactionTaxonomy.reload!
      @result
    end

    private

    def each_node(parents_only:)
      TransactionTaxonomy::KINDS.each do |kind|
        (@data[kind] || {}).each_with_index do |(pkey, pnode), p_pos|
          if parents_only
            yield pkey.to_s, kind, nil, pnode, p_pos
          else
            (pnode["children"] || {}).each_with_index do |(ckey, cnode), c_pos|
              yield ckey.to_s, kind, pkey.to_s, cnode, c_pos
            end
          end
        end
      end
    end

    def upsert(key, kind, parent_key, node, position)
      row = TaxonomyNode.find_or_initialize_by(key: key)

      if row.new_record?
        row.assign_attributes(kind: kind, parent_key: parent_key, name_en: node["en"],
                              name_fr: node["fr"], position: position, active: true)
        row.save!
        @result.created += 1
        return
      end

      @result.renamed += 1 if row.name_en != node["en"] || row.name_fr != node["fr"]
      @result.moved   += 1 if row.parent_key != parent_key

      row.assign_attributes(parent_key: parent_key, name_en: node["en"], name_fr: node["fr"],
                            position: position, active: true)
      row.save! if row.changed?
    end

    # Retired, not removed — transaction_types.template_key still points here.
    def deactivate_dropped
      known = yml_keys
      TaxonomyNode.active.where.not(key: known.to_a).find_each do |row|
        next if row.protected_key?

        row.update!(active: false)
        @result.deactivated += 1
      end
    end

    def yml_keys
      TransactionTaxonomy::KINDS.flat_map { |kind|
        (@data[kind] || {}).flat_map { |pkey, pnode| [ pkey.to_s, *(pnode["children"] || {}).keys.map(&:to_s) ] }
      }.to_set
    end
  end
end
