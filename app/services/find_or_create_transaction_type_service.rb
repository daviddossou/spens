# frozen_string_literal: true

class FindOrCreateTransactionTypeService
  def initialize(space, transaction_type_name, kind)
    @space = space
    @transaction_type_name = transaction_type_name
    @kind = kind
  end

  def call
    name = @transaction_type_name.strip

    existing = @space.transaction_types
                     .where(kind: @kind)
                     .where("lower(name) = ?", name.downcase)
                     .first
    return existing if existing

    @space.transaction_types.create!(kind: @kind, name: name, budget_goal: 0.0)
  end
end
