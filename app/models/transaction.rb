# == Schema Information
#
# Table name: transactions
#
#  id                  :uuid             not null, primary key
#  amount              :float            not null
#  description         :string           not null
#  note                :text
#  transaction_date    :date             not null, indexed
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :uuid             indexed
#  debt_id             :uuid             indexed
#  transaction_type_id :uuid             not null, indexed
#  user_id             :uuid             not null, indexed
#
# Indexes
#
#  index_transactions_on_account_id           (account_id)
#  index_transactions_on_debt_id              (debt_id)
#  index_transactions_on_transaction_date     (transaction_date)
#  index_transactions_on_transaction_type_id  (transaction_type_id)
#  index_transactions_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (debt_id => debts.id)
#  fk_rails_...  (transaction_type_id => transaction_types.id)
#  fk_rails_...  (user_id => users.id)
#
class Transaction < ApplicationRecord
  ##
  # Associations
  belongs_to :user
  belongs_to :transaction_type
  belongs_to :account, optional: true
  belongs_to :debt, optional: true

  ##
  # Nested Attributes
  accepts_nested_attributes_for :account
  accepts_nested_attributes_for :transaction_type

  ##
  # Validations
  validates :description, presence: true, length: { maximum: 255 }
  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :transaction_date, presence: true
  validate :account_presence_based_on_type

  ##
  # Callbacks
  after_save :update_account_balance
  after_save :update_debt_totals
  after_destroy :revert_account_balance
  after_destroy :revert_debt_totals

  private

  def update_account_balance
    return unless account

    account.balance = (account.balance || 0.0) + amount
    account.save!
  end

  def revert_account_balance
    return unless account

    account.balance = (account.balance || 0.0) - amount
    account.save!
  end

  def update_debt_totals
    return unless debt
    return unless transaction_type

    case transaction_type.kind
    when TransactionType::KIND_DEBT_OUT
      debt.total_lent = (debt.total_lent || 0.0) + amount.abs
      debt.save!
    when TransactionType::KIND_DEBT_IN
      debt.total_reimbursed = (debt.total_reimbursed || 0.0) + amount.abs
      debt.save!
    end
  end

  def revert_debt_totals
    return unless debt
    return unless transaction_type

    case transaction_type.kind
    when TransactionType::KIND_DEBT_OUT
      debt.total_lent = (debt.total_lent || 0.0) - amount.abs
      debt.save!
    when TransactionType::KIND_DEBT_IN
      debt.total_reimbursed = (debt.total_reimbursed || 0.0) - amount.abs
      debt.save!
    end
  end

  def account_presence_based_on_type
    return unless transaction_type.present?
    return if [TransactionType::KIND_DEBT_IN, TransactionType::KIND_DEBT_OUT].include?(transaction_type.kind)

    errors.add(:account, :blank) if account.nil?
  end
end
