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
#  account_id          :uuid             not null, indexed
#  transaction_type_id :uuid             not null, indexed
#  user_id             :uuid             not null, indexed
#
# Indexes
#
#  index_transactions_on_account_id           (account_id)
#  index_transactions_on_transaction_date     (transaction_date)
#  index_transactions_on_transaction_type_id  (transaction_type_id)
#  index_transactions_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (transaction_type_id => transaction_types.id)
#  fk_rails_...  (user_id => users.id)
#
class Transaction < ApplicationRecord
  ##
  # Associations
  belongs_to :user
  belongs_to :transaction_type
  belongs_to :account

  ##
  # Nested Attributes
  accepts_nested_attributes_for :account
  accepts_nested_attributes_for :transaction_type

  ##
  # Validations
  validates :description, presence: true, length: { maximum: 255 }
  validates :amount, presence: true, numericality: { other_than: 0 }
  validates :transaction_date, presence: true

  ##
  # Callbacks
  after_save :update_account_balance
  after_destroy :update_account_balance

  private

  def update_account_balance
    return unless account

    current_balance = account.balance || 0.0
    account.balance = current_balance + amount
    account.save!
  end
end
