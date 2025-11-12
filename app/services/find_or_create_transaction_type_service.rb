# frozen_string_literal: true

class FindOrCreateTransactionTypeService
  def initialize(user, transaction_type_name, kind)
    @user = user
    @transaction_type_name = transaction_type_name
    @kind = kind
  end

  def call
    @user.transaction_types.find_or_create_by!(kind: @kind, name: @transaction_type_name.strip) do |transaction_type|
      transaction_type.budget_goal = 0.0
    end
  end
end
