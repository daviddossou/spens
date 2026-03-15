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
#  space_id            :uuid             not null, indexed
#  transaction_type_id :uuid             not null, indexed
#
# Indexes
#
#  index_transactions_on_account_id           (account_id)
#  index_transactions_on_debt_id              (debt_id)
#  index_transactions_on_space_id             (space_id)
#  index_transactions_on_transaction_date     (transaction_date)
#  index_transactions_on_transaction_type_id  (transaction_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (debt_id => debts.id)
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (transaction_type_id => transaction_types.id)
#
class Transaction < ApplicationRecord
  ##
  # Associations
  belongs_to :space
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
  after_create :apply_account_balance
  after_create :apply_debt_totals
  after_update :adjust_account_balance, if: :saved_change_to_amount?
  after_update :adjust_debt_totals, if: :saved_change_to_amount?

  private

  def apply_account_balance
    return unless account

    account.balance = (account.balance || 0.0) + amount
    account.save!
  end

  def apply_debt_totals
    return unless debt
    return unless transaction_type

    is_debt_increase = (debt.lent? && transaction_type.debt_out?) ||
                       (debt.borrowed? && transaction_type.debt_in?)

    if is_debt_increase
      debt.increment!(:total_lent, amount.abs)
    else
      debt.increment!(:total_reimbursed, amount.abs)
    end
  end

  def adjust_account_balance
    return unless account

    old_amount, new_amount = saved_change_to_amount
    difference = new_amount - old_amount
    account.balance = (account.balance || 0.0) + difference
    account.save!
  end

  def adjust_debt_totals
    return unless debt
    return unless transaction_type

    old_amount, new_amount = saved_change_to_amount
    difference = new_amount.abs - old_amount.abs

    is_debt_increase = (debt.lent? && transaction_type.debt_out?) ||
                       (debt.borrowed? && transaction_type.debt_in?)

    if is_debt_increase
      debt.increment!(:total_lent, difference)
    else
      debt.increment!(:total_reimbursed, difference)
    end
  end

  def account_presence_based_on_type
    return unless transaction_type.present?
    return if [ TransactionType::KIND_DEBT_IN, TransactionType::KIND_DEBT_OUT ].include?(transaction_type.kind)

    errors.add(:account, :blank) if account.nil?
  end
end
