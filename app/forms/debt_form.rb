# frozen_string_literal: true

class DebtForm < BaseForm
  ##
  # Attributes
  attr_accessor :user, :debt

  attribute :contact_name, :string
  attribute :total_lent, :decimal
  attribute :total_reimbursed, :decimal, default: 0.0
  attribute :note, :string
  attribute :direction, :string, default: "lent"
  attribute :account_name, :string

  ##
  # Validations
  validates :contact_name, presence: true, length: { maximum: 100 }
  validates :total_lent, presence: true, numericality: { greater_than: 0 }
  validates :total_reimbursed, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validate :reimbursed_not_exceeding_lent
  validate :total_lent_not_less_than_existing, if: -> { debt.present? }
  validate :total_reimbursed_not_less_than_existing, if: -> { debt.present? }

  ##
  # Class Methods
  class << self
    def model_name
      ActiveModel::Name.new(self, nil, "Debt")
    end
  end

  ##
  # Instance Methods
  def initialize(user, payload = {})
    @user = user
    @debt = Debt.find(payload[:id]) if payload[:id].present?

    super(
      contact_name: payload[:contact_name],
      total_lent: payload[:total_lent],
      total_reimbursed: payload[:total_reimbursed] || 0.0,
      note: payload[:note],
      direction: payload[:direction] || "lent",
      account_name: payload[:account_name]
    )
  end

  def persisted?
    @debt.present?
  end

  def to_model
    self
  end

  def submit
    return false if invalid?

    ActiveRecord::Base.transaction do
      create_or_update_debt
      create_debt_out_transaction
      create_debt_in_transaction
      debt
    end
  rescue StandardError => e
    Rails.logger.error "DebtForm submit error: #{e.message}\n#{e.backtrace.join("\n")}"
    add_custom_error(:base, e.message)
    false
  end

  def account_suggestions
    AccountSuggestionsService.new(user).all
  end

  def default_account_suggestions
    AccountSuggestionsService.new(user).defaults
  end

  private

  def reimbursed_not_exceeding_lent
    return if total_lent.present? && total_reimbursed.present? && total_reimbursed <= total_lent

    errors.add(:total_reimbursed, I18n.t("debts.errors.reimbursed_exceeds_lent"))
  end

  def total_lent_not_less_than_existing
    return if total_lent.to_f >= (debt.total_lent || 0.0)

    errors.add(:total_lent, I18n.t("debts.errors.total_lent_cannot_be_less"))
  end

  def total_reimbursed_not_less_than_existing
    return if total_reimbursed.to_f >= (debt.total_reimbursed || 0.0)

    errors.add(:total_reimbursed, I18n.t("debts.errors.total_reimbursed_cannot_be_less"))
  end

  def create_or_update_debt
    debt_attributes = {
      name: contact_name,
      direction: direction,
      status: :ongoing,
      note: note
    }

    if @debt.nil?
      @debt = user.debts.create!(debt_attributes)
    else
      @debt.update!(debt_attributes)
    end
  end

  def create_debt_out_transaction
    difference = lent? ? lent_difference : reimbursed_difference
    create_transaction("debt_out", difference) if difference.positive?
  end

  def create_debt_in_transaction
    difference = lent? ? reimbursed_difference : lent_difference
    create_transaction("debt_in", difference) if difference.positive?
  end

  def lent_difference
    total_lent.to_f - (debt.total_lent || 0.0)
  end

  def reimbursed_difference
    total_reimbursed.to_f - (debt.total_reimbursed || 0.0)
  end

  def lent?
    direction == "lent"
  end

  def create_transaction(kind, amount)
    transaction_form = TransactionForm.new(
      user,
      amount: amount.abs,
      transaction_date: Date.current,
      kind: kind,
      debt_id: debt.id,
      account_name: account_name
    )

    transaction_form.submit

    raise StandardError, transaction_form.errors.full_messages.join(", ") unless transaction_form.errors.empty?
  end
end
