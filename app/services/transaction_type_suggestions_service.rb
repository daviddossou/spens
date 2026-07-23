# frozen_string_literal: true

# Supplies the category picker's two lists: #default_options (the focus view) and
# #options (the search universe).
class TransactionTypeSuggestionsService
  DEFAULT_LIMIT = 20

  def initialize(space, kind)
    @space = space
    @kind = kind
  end

  def options
    taxonomy_options + custom_options
  end

  def default_options
    picks = own_options
    if picks.size < DEFAULT_LIMIT
      used = picks.map { |o| o[:value] }.to_set
      picks += common_options.reject { |o| used.include?(o[:value]) }.take(DEFAULT_LIMIT - picks.size)
    end
    picks.take(DEFAULT_LIMIT)
  end

  private

  def taxonomy_options
    @taxonomy_options ||= TransactionTaxonomy.parent_keys(@kind).flat_map do |pkey|
      TransactionTaxonomy.child_keys(pkey).map { |ckey| option_for_key(ckey) }
    end
  end

  def taxonomy_names
    @taxonomy_names ||= taxonomy_options.map { |o| o[:value] }.to_set
  end

  def custom_options
    recorded_types.filter_map do |type|
      next if type.template_key.present? || taxonomy_names.include?(type.name)

      option_for_type(type)
    end
  end

  def own_options
    recorded_types.map { |type| option_for_type(type) }
  end

  # "Recorded" = appears on at least one transaction, which excludes the parent rows
  # auto-created for roll-up (they hold no transactions of their own). Most-recent first,
  # with the most-used (by number of transactions) breaking ties.
  def recorded_types
    @recorded_types ||= @space.transaction_types
      .where(kind: @kind)
      .joins(:transactions)
      .group("transaction_types.id")
      .order(updated_at: :desc)
      .order(Arel.sql("COUNT(transactions.id) DESC")).to_a
  end

  def common_options
    TransactionType.default_template_keys(@kind).filter_map do |key|
      option_for_key(key) if TransactionTaxonomy.exists?(key)
    end
  end

  # The space's own learned phrases per taxonomy key ("chez l'indien" -> monthly_provisions).
  # Carried separately from the shared aliases so the picker can rank a personal match first.
  def personal_terms
    @personal_terms ||= LearnedAlias.for_space(@space).active
      .pluck(:taxonomy_key, :display_phrase, :phrase)
      .group_by(&:first)
      .transform_values { |rows| rows.map { |_, display, phrase| display.presence || phrase }.join(" ") }
  end

  def option_for_key(key)
    name = TransactionTaxonomy.name(key)
    build_option(name, key)
  end

  def option_for_type(type)
    build_option(type.name, type.template_key)
  end

  def build_option(name, key)
    option = { value: name, text: name, aliases: key.present? ? CategoryAliasMatcher.terms(key) : "" }
    option[:personal_aliases] = personal_terms[key] if key.present? && personal_terms[key]
    option
  end
end
