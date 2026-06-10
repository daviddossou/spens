# frozen_string_literal: true

module QuickEntry
  # The structured result of parsing one utterance — maps onto TransactionForm's payload.
  Draft = Data.define(
    :kind, :amount, :account_name, :from_account_name, :to_account_name,
    :transaction_type_name, :fee_amount, :transaction_date, :description, :debt_id, :unresolved
  ) do
    CATEGORY_KINDS = %w[expense income].freeze
    DEBT_KINDS = %w[debt_in debt_out].freeze

    # Ruby's Data has no native defaults; this lets callers pass only what they parsed.
    def initialize(kind:, amount: nil, account_name: nil, from_account_name: nil,
                   to_account_name: nil, transaction_type_name: nil, fee_amount: nil,
                   transaction_date: nil, description: nil, debt_id: nil, unresolved: [])
      super
    end

    # Enough to auto-create without review; anything short falls back to the prefilled form.
    def confident?
      case kind
      when *CATEGORY_KINDS then amount.present? && transaction_type_name.present?
      when *DEBT_KINDS     then amount.present? && debt_id.present?
      when "transfer"      then amount.present? && from_account_name.present? && to_account_name.present?
      else false
      end
    end

    def to_form_payload
      {
        kind: kind,
        amount: amount,
        account_name: account_name,
        from_account_name: from_account_name,
        to_account_name: to_account_name,
        transaction_type_name: transaction_type_name,
        fee_amount: fee_amount,
        transaction_date: transaction_date,
        description: description,
        debt_id: debt_id
      }.compact
    end
  end
end
