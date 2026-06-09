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
  # auto-created for roll-up (they hold no transactions of their own). Newest first.
  def recorded_types
    @recorded_types ||= @space.transaction_types
      .where(kind: @kind)
      .where(id: Transaction.select(:transaction_type_id))
      .order(updated_at: :desc).to_a
  end

  def common_options
    TransactionType.default_template_keys(@kind).filter_map do |key|
      option_for_key(key) if TransactionTaxonomy.exists?(key)
    end
  end

  def option_for_key(key)
    name = TransactionTaxonomy.name(key)
    { value: name, text: name, aliases: CategoryAliasMatcher.terms(key) }
  end

  def option_for_type(type)
    key = type.template_key
    {
      value: type.name,
      text: type.name,
      aliases: key.present? ? CategoryAliasMatcher.terms(key) : ""
    }
  end
end
