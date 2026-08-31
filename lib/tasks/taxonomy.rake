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

  # Full tree + usage, aliases, coverage and gaps as JSON.
  #   bin/rails taxonomy:export            -> stdout
  #   OUT=tmp/taxonomy.json bin/rails taxonomy:export
  #   KIND=expense GAPS=false bin/rails taxonomy:export
  desc "Export the taxonomy (with usage and coverage) as JSON"
  task export: :environment do
    payload = TaxonomyExport.call(kind: ENV["KIND"], gaps: ENV["GAPS"] != "false",
                                  gap_limit: (ENV["GAP_LIMIT"] || 50).to_i)
    json = JSON.pretty_generate(payload)

    if (out = ENV["OUT"]).present?
      File.write(out, json)
      warn "taxonomy exported to #{out} (#{json.bytesize} bytes)"
    else
      puts json
    end
  end

  # Human-readable pass for deciding which parents stand on their own.
  #   bin/rails taxonomy:review
  desc "Print a review table of parents, their subtree usage and coverage"
  task review: :environment do
    data = TaxonomyExport.call(gaps: false)

    data[:kinds].each do |kind, parents|
      puts "\n===== #{kind.upcase} (#{parents.size} parents) ====="
      printf("%-26s %5s %7s %7s  %s\n", "KEY", "SUBS", "SPACES", "TX", "NAME (FR)")
      parents.sort_by { |p| -p[:subtree_usage][:transactions] }.each do |p|
        printf("%-26s %5d %7d %7d  %s\n", p[:key], p[:children].size,
               p[:subtree_usage][:spaces], p[:subtree_usage][:transactions], p[:name][:fr])
      end
    end

    c = data[:coverage]
    puts "\n===== COUVERTURE ====="
    if c[:transactions].to_i.zero?
      puts "aucune transaction"
    else
      puts "transactions           : #{c[:transactions]}"
      puts "fourre-tout (other/unc): #{c[:catch_all][:transactions]} (#{c[:catch_all][:percent]}%)"
      puts "categorie inventee     : #{c[:custom_category][:transactions]} (#{c[:custom_category][:percent]}%)"
      puts "NON COUVERT            : #{c[:uncovered][:transactions]} (#{c[:uncovered][:percent]}%)"
    end
  end
end
