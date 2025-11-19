# frozen_string_literal: true

class DebtForm < BaseForm
  ##
  # Attributes
  attr_accessor :user, :debt

  attribute :contact_name, :string
  attribute :total_lent, :decimal
  attribute :total_reimbursed, :decimal, default: 0.0
  attribute :note, :string
  attribute :direction, :string, default: 'lent'

  ##
  # Validations
  validates :contact_name, presence: true, length: { maximum: 100 }
  validates :total_lent, presence: true, numericality: { greater_than: 0 }
  validates :total_reimbursed, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validate :reimbursed_not_exceeding_lent

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
    super(
      contact_name: payload[:contact_name],
      total_lent: payload[:total_lent],
      total_reimbursed: payload[:total_reimbursed] || 0.0,
      note: payload[:note],
      direction: payload[:direction] || 'lent'
    )
  end

  def persisted?
    false
  end

  def to_model
    self
  end

  def submit
    return false if invalid?

    ActiveRecord::Base.transaction do
      debt = create_debt
      create_debt_out_transaction
      create_debt_in_transaction if total_reimbursed.to_f > 0.0
      debt
    end
  rescue StandardError => e
    Rails.logger.error "DebtForm submit error: #{e.message}\n#{e.backtrace.join("\n")}"
    add_custom_error(:base, e.message)
    false
  end

  private

  def reimbursed_not_exceeding_lent
    return if total_lent.present? && total_reimbursed.present? && total_reimbursed <= total_lent

    errors.add(:total_reimbursed, I18n.t('debts.errors.reimbursed_exceeds_lent'))
  end

  def create_debt
    debt_attributes = {
      name: contact_name,
      direction: direction,
      status: :ongoing,
      note: note
    }

    @debt = user.debts.create(debt_attributes)
    debt
  end

  def create_debt_out_transaction
    create_transaction('debt_out')
  end

  def create_debt_in_transaction
    create_transaction('debt_in')
  end

  def create_transaction(kind)
    transaction_form = TransactionForm.new(
      user,
      amount: total_lent.abs,
      transaction_date: Date.current,
      kind: kind,
      debt_id: debt.id
    )

    transaction_form.submit

    raise StandardError, transaction_form.errors.full_messages.join(", ") unless transaction_form.errors.empty?
  end
end
