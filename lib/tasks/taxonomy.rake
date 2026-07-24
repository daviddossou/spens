# frozen_string_literal: true

namespace :taxonomy do
  # Post-deploy: one-time seed of taxonomy_nodes from the YML tree, making the DB the
  # runtime source (TransactionTaxonomy falls back to the YML until this has run).
  # Creates missing keys only — existing rows are admin-owned and never touched.
  #   bin/rails taxonomy:import_nodes
  desc "Import config/transaction_taxonomy.yml into taxonomy_nodes"
  task import_nodes: :environment do
    data = YAML.load_file(TransactionTaxonomy::PATH)
    created = skipped = 0

    upsert = lambda do |key, kind, parent_key, node, position|
      row = TaxonomyNode.find_or_initialize_by(key: key.to_s)
      if row.new_record?
        row.update!(kind:, parent_key:, name_en: node["en"], name_fr: node["fr"], position:)
        created += 1
      else
        skipped += 1
      end
    end

    TransactionTaxonomy::KINDS.each do |kind|
      (data[kind] || {}).each_with_index do |(pkey, pnode), p_pos|
        upsert.call(pkey, kind, nil, pnode, p_pos)
        (pnode["children"] || {}).each_with_index do |(ckey, cnode), c_pos|
          upsert.call(ckey, kind, pkey.to_s, cnode, c_pos)
        end
      end
    end

    TransactionTaxonomy.reload!
    puts "taxonomy nodes: #{created} created, #{skipped} skipped (admin-owned)"
  end
end
