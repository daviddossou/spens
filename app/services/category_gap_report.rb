# frozen_string_literal: true

# Surfaces the categories users had to invent: custom transaction_types (no template_key)
# grouped by normalized name across all spaces. Each group is a taxonomy/vocabulary gap
# candidate for the admin queue — mapping it teaches a global alias, promoting it becomes a
# new taxonomy node. Names the global dictionary already resolves (or that were mapped or
# dismissed before) are filtered out, so the queue only ever shows open gaps.
class CategoryGapReport
  Gap = Struct.new(:phrase, :display_name, :kind, :space_count, :transaction_count, :samples,
                   keyword_init: true)

  SAMPLE_LIMIT = 3

  class << self
    def build(limit: 50)
      types = TransactionType.where(template_key: nil, kind: %w[expense income]).to_a
      groups = types.group_by { |t| [ t.kind, CategoryText.normalize(t.name) ] }
      known = LearnedAlias.global.where(phrase: groups.keys.map(&:last).uniq).pluck(:phrase).to_set
      tx_counts = Transaction.where(transaction_type_id: types.map(&:id))
                             .group(:transaction_type_id).count

      gaps = groups.filter_map do |(kind, phrase), group|
        next if phrase.blank? || known.include?(phrase) || resolved?(phrase)

        Gap.new(
          phrase: phrase,
          display_name: group.map(&:name).tally.max_by(&:last).first,
          kind: kind,
          space_count: group.map(&:space_id).uniq.size,
          transaction_count: group.sum { |t| tx_counts[t.id].to_i },
          samples: []
        )
      end

      gaps = gaps.sort_by { |g| [ -g.space_count, -g.transaction_count ] }.first(limit)
      attach_samples(gaps, groups)
      gaps
    end

    private

    # Already covered by the built-in vocabulary: an alias match or a taxonomy name in
    # either language means the user could have found it by typing.
    def resolved?(phrase)
      CategoryAliasMatcher.match(phrase).present? || TransactionTaxonomy.key_for_name(phrase).present?
    end

    def attach_samples(gaps, groups)
      gaps.each do |gap|
        type_ids = groups[[ gap.kind, gap.phrase ]].map(&:id)
        gap.samples = Transaction.where(transaction_type_id: type_ids)
                                 .where.not(description: [ nil, "" ])
                                 .distinct.limit(SAMPLE_LIMIT).pluck(:description)
      end
    end
  end
end
