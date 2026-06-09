# frozen_string_literal: true

# Files a space's existing transaction types into the category tree, non-destructively:
#   - an exact canonical name ("🛒 Groceries")  -> sets template_key + links its parent
#   - an alias name ("Zem", "Carrefour")        -> links the alias's parent only (stays a custom leaf)
#   - anything unrecognised                      -> left untouched (its own analytics slice)
# Names and transactions are never changed; only template_key / parent_id are set. Idempotent.
class BackfillCategoryHierarchy
  CATEGORISED_KINDS = %w[expense income].freeze

  def initialize(space)
    @space = space
  end

  def call
    pending_types.each { |type| backfill(type) }
  end

  private

  # Snapshot before we start creating parent rows, so we only process pre-existing leaves.
  def pending_types
    @space.transaction_types.where(kind: CATEGORISED_KINDS, template_key: nil).to_a
  end

  def backfill(type)
    if (key = exact_key(type)) then assign(type, key, set_template: true)
    elsif (key = alias_key(type)) then assign(type, key, set_template: false)
    end
  end

  def exact_key(type)
    key = TransactionTaxonomy.key_for_name(type.name)
    key if key && TransactionTaxonomy.kind_of(key) == type.kind
  end

  def alias_key(type)
    key = CategoryAliasMatcher.match(type.name)
    key if key && TransactionTaxonomy.kind_of(key) == type.kind
  end

  def assign(type, key, set_template:)
    parent = find_or_create_parent(TransactionTaxonomy.parent_key(key))

    if set_template && !template_key_taken?(key, type)
      type.update!(template_key: key, parent: parent)
    else
      type.update!(parent: parent)
    end
  end

  def template_key_taken?(key, type)
    @space.transaction_types.where(template_key: key).where.not(id: type.id).exists?
  end

  def find_or_create_parent(parent_key)
    return nil unless parent_key

    @space.transaction_types.find_by(template_key: parent_key) || create_parent(parent_key)
  end

  def create_parent(parent_key)
    name = TransactionTaxonomy.name(parent_key)
    kind = TransactionTaxonomy.kind_of(parent_key)

    if (existing = @space.transaction_types.where(kind: kind).where("lower(name) = ?", name.downcase).first)
      existing.update!(template_key: parent_key) if existing.template_key.nil?
      existing
    else
      @space.transaction_types.create!(template_key: parent_key, name: name, kind: kind, budget_goal: 0.0)
    end
  end
end
