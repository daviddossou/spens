# frozen_string_literal: true

# Base for the form-level write use-cases (BuildTransaction, EditTransaction):
# resolves accounts/types/fees from the submitted form and persists rows through
# the row-level Create/Update/Destroy services. Subclasses implement #call.
class TransactionWriter
  def initialize(form)
    @form = form
  end

  private

  attr_reader :form

  delegate :space, :user, :kind, :amount, :fee_amount, :transaction_date,
           :note, :description, :account_name, :from_account_name, :to_account_name,
           :transaction_type_name, :contact_name, :direction, :debt, :transaction,
           :transfer?, :debt_transaction?, :fee_applicable?, to: :form

  def create_and_validate_transaction(account:, transaction_type:, amount:, description:, debt: nil, transfer_group_id: nil, fee_parent_id: nil)
    transaction = CreateTransactionService.new(
      space: space,
      user: user,
      account: account,
      transaction_type: transaction_type,
      amount: amount.abs,
      transaction_date: transaction_date,
      note: note,
      description: description,
      debt: debt,
      transfer_group_id: transfer_group_id,
      fee_parent_id: fee_parent_id
    ).call

    if transaction.invalid?
      transaction.errors.messages.each { |attr, msgs| form.errors.add(attr, msgs.first) }
      raise ActiveRecord::RecordInvalid, transaction
    end

    transaction
  end

  def build_fee(account:, parent:)
    return unless fee_present?

    create_and_validate_transaction(
      account: account,
      transaction_type: fee_transaction_type,
      amount: fee_amount,
      description: fee_description(account),
      fee_parent_id: parent&.id
    )
  end

  # A predicate so the transfer path can skip resolving the source account (which
  # would find-or-create a stray account) when there is no fee to record.
  def fee_present?
    fee_applicable? && fee_amount.present? && fee_amount.positive?
  end

  def fee_description(account)
    if transfer?
      I18n.t("transactions.transfer.fee_description",
             from_account_name: from_account.name, to_account_name: to_account.name)
    else
      label = description.presence || transaction_type_name.presence ||
              contact_name.presence || account&.name
      I18n.t("transactions.fee.description", label: label)
    end
  end

  def find_or_create_account
    return nil if account_name.blank?

    FindOrCreateAccountService.new(space, account_name).call
  end

  def find_or_create_transaction_type(type_name = transaction_type_name, kind_name = kind)
    FindOrCreateTransactionTypeService.new(space, type_name, kind_name).call
  end

  def from_account
    @from_account ||= FindOrCreateAccountService.new(space, (from_account_name || account_name)).call
  end

  def to_account
    @to_account ||= FindOrCreateAccountService.new(space, (to_account_name || account_name)).call
  end

  def transfer_type_out
    @transfer_type_out ||= find_or_create_transaction_type(
      I18n.t("transactions.transfer.type_name.#{TransactionType::KIND_TRANSFER_OUT}"),
      TransactionType::KIND_TRANSFER_OUT
    )
  end

  def transfer_type_in
    @transfer_type_in ||= find_or_create_transaction_type(
      I18n.t("transactions.transfer.type_name.#{TransactionType::KIND_TRANSFER_IN}"),
      TransactionType::KIND_TRANSFER_IN
    )
  end

  def fee_transaction_type
    @fee_transaction_type ||= find_or_create_transaction_type(
      TransactionTaxonomy.name(TransactionType::FEE_KEY), "expense"
    )
  end

  def transfer_leg_description(side)
    I18n.t("transactions.transfer.description_#{side}",
           from_account_name: from_account.name, to_account_name: to_account.name)
  end
end
