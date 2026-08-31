# frozen_string_literal: true

# Read-only snapshot of the whole category tree plus the evidence needed to review it:
# per-node usage across spaces, the vocabulary that resolves to each node, and the two
# coverage signals that say whether the tree is exhaustive (catch-all share, invented
# categories). Feeds Admin::TaxonomyExportsController and `rake taxonomy:export`.
class TaxonomyExport
  CATCH_ALL_KEYS = TaxonomyNode::PROTECTED_KEYS
  ALIAS_SAMPLE_LIMIT = 12

  def self.call(**) = new(**).call

  def initialize(kind: nil, gaps: true, gap_limit: 50)
    @kind = kind.presence&.to_s
    @gaps = gaps
    @gap_limit = gap_limit
  end

  def call
    {
      generated_at: Time.current.iso8601,
      source: db_backed? ? "taxonomy_nodes" : "yml_fallback",
      counts: counts,
      coverage: coverage,
      kinds: tree,
      inactive: inactive_nodes,
      gaps: (@gaps ? gaps_payload : nil)
    }.compact
  end

  private

  def kinds = @kind ? [ @kind ] : TransactionTaxonomy::KINDS

  def db_backed? = @db_backed ||= TaxonomyNode.exists?

  def counts
    kinds.index_with do |kind|
      parents = TransactionTaxonomy.parent_keys(kind)
      { parents: parents.size, children: parents.sum { |p| TransactionTaxonomy.child_keys(p).size } }
    end
  end

  # The two questions a "parents only" decision hangs on: how often does spend fall into a
  # catch-all bucket, and how often did a user have to invent a category outright.
  def coverage
    total = Transaction.count
    return { transactions: 0 } if total.zero?

    { transactions: total,
      catch_all: share(catch_all_transactions, total),
      custom_category: share(custom_transactions, total),
      uncovered: share(catch_all_transactions + custom_transactions, total) }
  end

  def share(count, total)
    { transactions: count, percent: (count * 100.0 / total).round(2) }
  end

  def catch_all_transactions
    @catch_all_transactions ||=
      Transaction.where(transaction_type_id: TransactionType.where(template_key: CATCH_ALL_KEYS).select(:id)).count
  end

  def custom_transactions
    @custom_transactions ||=
      Transaction.where(transaction_type_id: TransactionType.where(template_key: nil).select(:id)).count
  end

  def tree
    kinds.index_with do |kind|
      TransactionTaxonomy.parent_keys(kind).map do |pkey|
        node_payload(pkey, kind).merge(
          children: TransactionTaxonomy.child_keys(pkey).map { |ckey| node_payload(ckey, kind) },
          subtree_usage: subtree_usage(pkey)
        )
      end
    end
  end

  def node_payload(key, kind)
    row = db_rows[key]
    { key: key,
      kind: kind,
      name: { en: TransactionTaxonomy.node(key)&.dig("en"), fr: TransactionTaxonomy.node(key)&.dig("fr") },
      position: row&.position,
      catch_all: CATCH_ALL_KEYS.include?(key),
      usage: usage_for(key),
      aliases: aliases_for(key) }.compact
  end

  # A parent's own hits plus every child's — what a parent-level budget would actually capture.
  def subtree_usage(pkey)
    keys = [ pkey, *TransactionTaxonomy.child_keys(pkey) ]
    { spaces: keys.flat_map { |k| usage[k][:spaces].to_a }.uniq.size,
      transactions: keys.sum { |k| usage[k][:transactions] } }
  end

  def usage_for(key)
    { spaces: usage[key][:spaces].size, transactions: usage[key][:transactions] }
  end

  def usage
    @usage ||= Hash.new { |h, k| h[k] = { spaces: Set.new, transactions: 0 } }.tap do |acc|
      template_types.each do |id, template_key, space_id|
        acc[template_key][:spaces] << space_id
        acc[template_key][:transactions] += type_tx_counts[id].to_i
      end
    end
  end

  def template_types
    @template_types ||= TransactionType.where.not(template_key: nil).pluck(:id, :template_key, :space_id)
  end

  def type_tx_counts
    @type_tx_counts ||= Transaction.where(transaction_type_id: template_types.map(&:first))
                                   .group(:transaction_type_id).count
  end

  # The vocabulary that resolves to a node: how many phrases point here, and a readable sample.
  def aliases_for(key)
    rows = alias_index[key] or return nil
    { count: rows.size, sample: rows.first(ALIAS_SAMPLE_LIMIT) }
  end

  def alias_index
    @alias_index ||= LearnedAlias.global.active
                                .pluck(:taxonomy_key, :display_phrase, :phrase)
                                .group_by(&:first)
                                .transform_values { |rows| rows.map { |(_, display, phrase)| display.presence || phrase }.sort }
  end

  def inactive_nodes
    return nil unless db_backed?

    rows = TaxonomyNode.where(active: false).ordered
    rows = rows.where(kind: @kind) if @kind
    payload = rows.map { |n| { key: n.key, kind: n.kind, parent_key: n.parent_key, name: { en: n.name_en, fr: n.name_fr } } }
    payload.presence
  end

  def db_rows
    @db_rows ||= db_backed? ? TaxonomyNode.all.index_by(&:key) : {}
  end

  def gaps_payload
    CategoryGapReport.build(limit: @gap_limit).filter_map do |gap|
      next if @kind && gap.kind != @kind

      { phrase: gap.phrase, display_name: gap.display_name, kind: gap.kind,
        spaces: gap.space_count, transactions: gap.transaction_count, samples: gap.samples }
    end
  end
end
