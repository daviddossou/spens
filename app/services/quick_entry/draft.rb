# frozen_string_literal: true

module QuickEntry
  # The structured result of parsing one utterance — maps onto TransactionForm's payload.
  Draft = Data.define(
    :kind, :amount, :account_name, :from_account_name, :to_account_name,
    :transaction_type_name, :fee_amount, :transaction_date, :description, :note, :label,
    :debt_id, :contact_name, :direction, :unresolved
  ) do
    CATEGORY_KINDS = %w[expense income].freeze
    DEBT_KINDS = %w[debt_in debt_out].freeze

    # Ruby's Data has no native defaults; this lets callers pass only what they parsed.
    def initialize(kind:, amount: nil, account_name: nil, from_account_name: nil,
                   to_account_name: nil, transaction_type_name: nil, fee_amount: nil,
                   transaction_date: nil, description: nil, note: nil, label: nil, debt_id: nil,
                   contact_name: nil, direction: nil, unresolved: [])
      super
    end

    # Enough to auto-create without review. Debts also auto-create a NEW counterparty when the
    # direction is clear (a known debt links by id; a new one is created from name + direction on
    # submit) — but never when the direction itself is unresolved. New accounts still need the form.
    def confident?
      case kind
      when *CATEGORY_KINDS then amount.present? && transaction_type_name.present?
      when *DEBT_KINDS     then amount.present? && (debt_id.present? || (contact_name.present? && direction.present?)) && unresolved.exclude?(:direction)
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
        note: note,
        label: label,
        debt_id: debt_id,
        contact_name: contact_name,
        direction: direction
      }.compact
    end
  end
end
