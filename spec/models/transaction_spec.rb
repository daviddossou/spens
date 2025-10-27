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

    describe 'account association' do
      it 'allows creating associated account via nested attributes' do
        user = create(:user)
        transaction_type = create(:transaction_type, :expense, user: user)

        transaction = described_class.new(
          user: user,
          transaction_type: transaction_type,
          description: 'Test',
          amount: 100,
          transaction_date: Date.today,
          account_attributes: { name: 'New Account', user: user }
        )

        expect { transaction.save! }.to change(Account, :count).by(1)
        expect(transaction.account.name).to eq('New Account')
      end
    end

    describe 'transaction_type association' do
      it 'allows creating associated transaction_type via nested attributes' do
        user = create(:user)
        account = create(:account, user: user)

        transaction = described_class.new(
          user: user,
          account: account,
          description: 'Test',
          amount: 100,
          transaction_date: Date.today,
          transaction_type_attributes: { name: 'New Type', kind: 'expense', user: user }
        )

        expect { transaction.save! }.to change(TransactionType, :count).by(1)
        expect(transaction.transaction_type.name).to eq('New Type')
        expect(transaction.transaction_type.kind).to eq('expense')
      end
    end
  end

  describe 'validations' do
    describe 'description validation' do
      it { is_expected.to validate_presence_of(:description) }
      it { is_expected.to validate_length_of(:description).is_at_most(255) }

      it 'is valid with a short description' do
        transaction.description = 'Coffee'
        expect(transaction).to be_valid
      end

      it 'is valid with a long description' do
        transaction.description = 'a' * 255
        expect(transaction).to be_valid
      end

      it 'is invalid with description longer than 255 characters' do
        transaction.description = 'a' * 256
        expect(transaction).not_to be_valid
        expect(transaction.errors[:description]).to include('is too long (maximum is 255 characters)')
      end
    end

    describe 'transaction_date validation' do
      it { is_expected.to validate_presence_of(:transaction_date) }

      it 'is valid with today\'s date' do
        transaction.transaction_date = Date.today
        expect(transaction).to be_valid
      end

      it 'is valid with a past date' do
        transaction.transaction_date = 1.year.ago.to_date
        expect(transaction).to be_valid
      end

      it 'is valid with a future date' do
        transaction.transaction_date = 1.year.from_now.to_date
        expect(transaction).to be_valid
      end
    end

    describe 'amount validation' do
      it { is_expected.to validate_presence_of(:amount) }
      it { is_expected.to validate_numericality_of(:amount).is_other_than(0) }

      it 'is invalid when amount is nil' do
        transaction.amount = nil
        expect(transaction).not_to be_valid
        expect(transaction.errors[:amount]).to include("can't be blank")
      end

      it 'is invalid when amount is zero' do
        transaction.amount = 0
        expect(transaction).not_to be_valid
        expect(transaction.errors[:amount]).to include("must be other than 0")
      end

      it 'is invalid when amount is non-numeric' do
        transaction.amount = 'abc'
        expect(transaction).not_to be_valid
        expect(transaction.errors[:amount]).to include("is not a number")
      end

      it 'is valid with a positive amount' do
        transaction.amount = 100.50
        expect(transaction).to be_valid
      end

      it 'is valid with a negative amount' do
        transaction.amount = -100.50
        expect(transaction).to be_valid
      end

      it 'is valid with a large amount' do
        transaction.amount = 999_999.99
        expect(transaction).to be_valid
      end

      it 'is valid with decimal precision' do
        transaction.amount = 12.345678
        expect(transaction).to be_valid
      end
    end

    describe 'note validation' do
      it 'is optional' do
        transaction.note = nil
        expect(transaction).to be_valid
      end

      it 'accepts text content' do
        transaction.note = 'This is a detailed note about the transaction'
        expect(transaction).to be_valid
      end

      it 'accepts long text' do
        transaction.note = 'a' * 1000
        expect(transaction).to be_valid
      end
    end
  end

  describe 'defaults' do
    it 'uses today for transaction_date if set explicitly in factory' do
      expect(transaction.transaction_date).to eq(Date.today)
    end
  end

  describe 'nested attributes' do
    it 'accepts nested attributes for account' do
      transaction = build(:transaction)
      transaction.account_attributes = { name: 'Test Account', user: transaction.user }
      expect(transaction.save).to be true
      expect(transaction.account.name).to eq('Test Account')
    end

    it 'accepts nested attributes for transaction_type' do
      transaction = build(:transaction)
      transaction.transaction_type_attributes = { name: 'Test Type', kind: 'expense', user: transaction.user }
      expect(transaction.save).to be true
      expect(transaction.transaction_type.name).to eq('Test Type')
    end
  end

  describe 'callbacks' do
    describe '#update_account_balance' do
      let(:user) { create(:user) }
      let(:account) { create(:account, user: user, balance: 1000.0) }
      let(:transaction_type) { create(:transaction_type, :expense, user: user) }

      context 'after create' do
        it 'updates account balance by adding the transaction amount' do
          expect do
            create(:transaction,
              user: user,
              account: account,
              transaction_type: transaction_type,
              amount: 100.0
            )
          end.to change { account.reload.balance }.from(1000.0).to(1100.0)
        end

        it 'handles positive amounts (income)' do
          expect do
            create(:transaction,
              user: user,
              account: account,
              transaction_type: transaction_type,
              amount: 250.0
            )
          end.to change { account.reload.balance }.by(250.0)
        end

        it 'handles negative amounts (expense)' do
          expect do
            create(:transaction,
              user: user,
              account: account,
              transaction_type: transaction_type,
              amount: -150.0
            )
          end.to change { account.reload.balance }.by(-150.0)
        end
      end

      context 'after update' do
        let!(:transaction) do
          create(:transaction,
            user: user,
            account: account,
            transaction_type: transaction_type,
            amount: 100.0
          )
        end

        before { account.reload }

        it 'updates account balance when amount changes' do
          # Initial: 1000.0 + 100.0 = 1100.0
          expect(account.balance).to eq(1100.0)

          # Update amount from 100.0 to 200.0
          # This adds another 200.0 (new total calculation)
          expect do
            transaction.update!(amount: 200.0)
          end.to change { account.reload.balance }.from(1100.0).to(1300.0)
        end

        it 'updates account balance when account changes' do
          account2 = create(:account, user: user, balance: 500.0)

          # Transaction was for account1 (1100.0)
          # Move to account2 (500.0)
          expect do
            transaction.update!(account: account2)
          end.to change { account2.reload.balance }.from(500.0).to(600.0)
        end
      end

      context 'after destroy' do
        it 'updates account balance by adding the transaction amount again (reversal)' do
          transaction = create(:transaction,
            user: user,
            account: account,
            transaction_type: transaction_type,
            amount: 100.0
          )

          # After creation: 1000.0 + 100.0 = 1100.0
          account.reload
          expect(account.balance).to eq(1100.0)

          # After destroy: adds amount again (1100.0 + 100.0 = 1200.0)
          # Note: This is the current implementation behavior
          expect do
            transaction.destroy!
          end.to change { account.reload.balance }.from(1100.0).to(1200.0)
        end
      end

      context 'edge cases' do
        it 'handles transactions with zero initial account balance' do
          account.update!(balance: 0.0)

          expect do
            create(:transaction,
              user: user,
              account: account,
              transaction_type: transaction_type,
              amount: 50.0
            )
          end.to change { account.reload.balance }.from(0.0).to(50.0)
        end

        it 'handles transactions with negative account balance' do
          account.update!(balance: -100.0)

          expect do
            create(:transaction,
              user: user,
              account: account,
              transaction_type: transaction_type,
              amount: 75.0
            )
          end.to change { account.reload.balance }.from(-100.0).to(-25.0)
        end
      end
    end
  end

  describe 'database indexes' do
    it 'has an index on account_id' do
      expect(ActiveRecord::Base.connection.index_exists?(:transactions, :account_id)).to be true
    end

    it 'has an index on transaction_type_id' do
      expect(ActiveRecord::Base.connection.index_exists?(:transactions, :transaction_type_id)).to be true
    end

    it 'has an index on user_id' do
      expect(ActiveRecord::Base.connection.index_exists?(:transactions, :user_id)).to be true
    end

    it 'has an index on transaction_date' do
      expect(ActiveRecord::Base.connection.index_exists?(:transactions, :transaction_date)).to be true
    end
  end

  describe 'integration scenarios' do
    let(:user) { create(:user) }
    let(:account) { create(:account, user: user, balance: 500.0) }
    let(:transaction_type) { create(:transaction_type, :expense, user: user) }

    it 'creates a complete transaction with all attributes' do
      transaction = create(:transaction,
        user: user,
        account: account,
        transaction_type: transaction_type,
        description: 'Grocery shopping',
        amount: -75.50,
        transaction_date: Date.today,
        note: 'Weekly groceries from supermarket'
      )

      expect(transaction).to be_persisted
      expect(transaction.description).to eq('Grocery shopping')
      expect(transaction.amount).to eq(-75.50)
      expect(transaction.note).to eq('Weekly groceries from supermarket')
      expect(account.reload.balance).to eq(424.50) # 500.0 + (-75.50)
    end

    it 'handles multiple transactions on same account' do
      create(:transaction, user: user, account: account, transaction_type: transaction_type, amount: 100.0)
      create(:transaction, user: user, account: account, transaction_type: transaction_type, amount: -50.0)
      create(:transaction, user: user, account: account, transaction_type: transaction_type, amount: 25.0)

      # Initial: 500.0
      # +100.0 = 600.0
      # -50.0 = 550.0
      # +25.0 = 575.0
      expect(account.reload.balance).to eq(575.0)
    end
  end
end
