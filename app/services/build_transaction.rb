# frozen_string_literal: true

# Creates the transaction(s) for a new submission (regular, transfer pair, or
# debt), plus an optional fee. Returns the primary transaction.
class BuildTransaction < TransactionWriter
  def call
    if transfer?
      build_transfer
    elsif debt_transaction?
      build_debt
    else
      build_regular
    end
  end

  private

  def build_regular
    account = find_or_create_account
    txn = create_and_validate_transaction(
      account: account,
      transaction_type: find_or_create_transaction_type,
      amount: amount,
      description: description.presence || transaction_type_name
    )
    build_fee(account: account, parent: txn)
    txn
  end

  def build_transfer
    group_id = SecureRandom.uuid
    in_leg  = build_transfer_leg(:in, group_id)  if %w[transfer transfer_in].include?(kind)
    out_leg = build_transfer_leg(:out, group_id) if %w[transfer transfer_out].include?(kind)
    build_fee(account: from_account, parent: out_leg || in_leg) if fee_present?
    out_leg || in_leg
  end

  def build_transfer_leg(side, group_id)
    account = side == :in ? to_account : from_account
    type = side == :in ? transfer_type_in : transfer_type_out
    create_and_validate_transaction(
      account: account,
      transaction_type: type,
      amount: amount,
      description: description.presence || transaction_type_name.presence || transfer_leg_description(side),
      transfer_group_id: group_id
    )
  end

  def build_debt
    account = find_or_create_account
    txn = create_and_validate_transaction(
      account: account,
      transaction_type: find_or_create_transaction_type(debt_type_name, kind),
      amount: amount,
      description: description.presence || debt_auto_description,
      debt: debt
    )
    build_fee(account: account, parent: txn)
    txn
  end

  def debt_type_name
    I18n.t("debts.transaction_type.#{kind}.#{debt.direction}")
  end

  def debt_auto_description
    I18n.t("debts.transaction_description.#{kind}.#{debt.direction}", contact_name: debt.name)
  end
end
