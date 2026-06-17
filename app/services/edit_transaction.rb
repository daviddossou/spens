# frozen_string_literal: true

# Applies an edit to an existing transaction, including kind conversions across
# families (regular ↔ debt ↔ transfer). The opened row keeps its id; transfers
# are the only multi-row case. Returns the edited (opened) transaction.
class EditTransaction < TransactionWriter
  def call
    result = perform_update
    sync_fee(result)
    result
  end

  private

  def perform_update
    if TransactionKind.transfer?(kind) || TransactionKind.transfer?(old_kind)
      update_transfer_involved
    else
      update_single_row(transaction, target_debt: debt_transaction? ? debt : nil)
    end
  end

  # Create, update, or remove the linked fee to match the submitted fee_amount.
  def sync_fee(result)
    parent = fee_parent(result)
    return unless parent

    existing = parent.fee
    if fee_present?
      existing ? update_fee(existing, parent) : build_fee(account: parent.account, parent: parent)
    elsif existing
      DestroyTransactionService.new(existing).call
    end
  end

  # The fee attaches to the money-out side: the out leg of a transfer, else the row itself.
  def fee_parent(result)
    TransactionKind.transfer?(result.transaction_type.kind) ? result.transfer_legs[:out] : result
  end

  def update_fee(fee, parent)
    UpdateTransactionService.new(
      transaction: fee,
      attributes: {
        amount: fee_amount,
        account_name: parent.account&.name,
        description: fee_description(parent.account),
        transaction_date: transaction_date
      }
    ).call
  end

  def old_kind
    @old_kind ||= transaction.transaction_type.kind
  end

  def update_single_row(record, target_debt:, account_name_value: account_name, extra: {})
    type_name = target_debt ? debt_type_name(target_debt) : transaction_type_name

    apply_update(record, {
      kind: kind,
      description: resolved_description(type_name, target_debt),
      transaction_date: transaction_date,
      transaction_type_name: type_name,
      account_name: account_name_value,
      amount: amount,
      note: note,
      debt: target_debt
    }.merge(extra))
  end

  def apply_update(record, attributes)
    UpdateTransactionService.new(transaction: record, attributes: attributes).call
  end

  def debt_type_name(target_debt)
    I18n.t("debts.transaction_type.#{kind}.#{target_debt.direction}")
  end

  # Blank description regenerates the create-path default.
  def resolved_description(type_name, target_debt)
    return description if description.present?

    if target_debt
      I18n.t("debts.transaction_description.#{kind}.#{target_debt.direction}", contact_name: target_debt.name)
    else
      type_name
    end
  end

  def update_transfer_involved
    if TransactionKind.transfer?(old_kind) && kind == "transfer"
      update_transfer_pair
    elsif TransactionKind.transfer?(old_kind)
      convert_transfer_to_single
    else
      convert_single_to_transfer
    end
  end

  def update_transfer_pair
    legs = transaction.transfer_legs
    update_transfer_leg(legs[:out], :out, from_account) if legs[:out]
    update_transfer_leg(legs[:in], :in, to_account) if legs[:in]
    transaction
  end

  def update_transfer_leg(leg, side, account)
    type = side == :in ? transfer_type_in : transfer_type_out
    apply_update(leg, {
      kind: type.kind,
      transaction_type_name: type.name,
      account_name: account.name,
      amount: amount,
      description: description.presence || transfer_leg_description(side),
      transaction_date: transaction_date,
      note: note
    })
  end

  # Convert the opened leg in place, drop the pairing, remove the partner leg.
  def convert_transfer_to_single
    partner = transaction.transfer_partner
    target_debt = debt_transaction? ? debt : nil

    result = update_single_row(transaction, target_debt: target_debt, extra: { transfer_group_id: nil })
    DestroyTransactionService.new(partner).call if partner
    result
  end

  # Opened row becomes one leg (out when money currently leaves); create the partner.
  def convert_single_to_transfer
    group_id = SecureRandom.uuid
    opened_out = TransactionKind.money_out?(old_kind)
    opened_side = opened_out ? :out : :in
    partner_side = opened_out ? :in : :out

    result = apply_update(transaction, {
      kind: transfer_type(opened_side).kind,
      transaction_type_name: transfer_type(opened_side).name,
      account_name: transfer_account(opened_side).name,
      amount: amount,
      description: description.presence || transfer_leg_description(opened_side),
      transaction_date: transaction_date,
      note: note,
      debt: nil,
      transfer_group_id: group_id
    })

    create_and_validate_transaction(
      account: transfer_account(partner_side),
      transaction_type: transfer_type(partner_side),
      amount: amount,
      description: transfer_leg_description(partner_side),
      transfer_group_id: group_id
    )

    result
  end

  def transfer_type(side)
    side == :out ? transfer_type_out : transfer_type_in
  end

  def transfer_account(side)
    side == :out ? from_account : to_account
  end
end
