# frozen_string_literal: true

class FindOrCreateTransactionTypeService
  def initialize(space, transaction_type_name, kind)
    @space = space
    @transaction_type_name = transaction_type_name
    @kind = kind.to_s
  end

  def call
    name = @transaction_type_name.to_s.strip

    if (key = resolve_key(name))
      materialize(key)
    else
      find_or_create_by_name(name, @kind)
    end
  end

  private

  # Resolve a submitted name to a taxonomy node ONLY when it IS a node's display name
  # (i.e. the user picked a suggestion). Free text the user typed is never silently
  # rewritten here — alias suggestion happens in the picker, not on the server.
  def resolve_key(name)
    key = TransactionTaxonomy.key_for_name(name)
    key if key && TransactionTaxonomy.kind_of(key) == @kind
  end

  # Find-or-create the per-space row for a taxonomy node, materialising its parent too,
  # and adopting an existing same-named row rather than duplicating it.
  def materialize(key)
    key = key.to_s
    by_key = @space.transaction_types.find_by(template_key: key)
    return by_key if by_key

    kind = TransactionTaxonomy.kind_of(key)
    name = TransactionTaxonomy.name(key)
    parent = (parent_key = TransactionTaxonomy.parent_key(key)) ? materialize(parent_key) : nil

    if (existing = find_by_name(name, kind))
      existing.update!(template_key: key, parent: parent)
      existing
    else
      @space.transaction_types.create!(
        template_key: key, name: name, kind: kind, budget_goal: 0.0, parent: parent
      )
    end
  end

  def find_or_create_by_name(name, kind)
    find_by_name(name, kind) || @space.transaction_types.create!(kind: kind, name: name, budget_goal: 0.0)
  end

  def find_by_name(name, kind)
    @space.transaction_types.where(kind: kind).where("lower(name) = ?", name.downcase).first
  end
end
