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
require 'rails_helper'

RSpec.describe Transaction, type: :model do
  subject(:transaction) { build(:transaction) }

  describe 'factory' do
    it 'is valid' do
      expect(transaction).to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:transaction_type) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(255) }
    it { is_expected.to validate_presence_of(:transaction_date) }

    it 'validates amount presence and non-zero numeric' do
      transaction.amount = nil
      expect(transaction).not_to be_valid
      expect(transaction.errors[:amount]).to include("can't be blank")

      transaction.amount = 0
      transaction.validate
      expect(transaction.errors[:amount]).to include("must be other than 0")

      transaction.amount = 'abc'
      transaction.validate
      # For non-numeric, Rails adds not a number error before other_than
      expect(transaction.errors[:amount]).to include("is not a number")

      transaction.amount = -12.34
      expect(transaction).to be_valid
    end
  end

  describe 'defaults' do
    it 'uses today for transaction_date if set explicitly in factory' do
      expect(transaction.transaction_date).to eq(Date.today)
    end
  end
end

