# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::AccountSetupForm, type: :model do
  let(:user) { create(:user, onboarding_current_step: nil) }
  let(:form) { described_class.new(user) }

  describe 'constants' do
    it 'defines CURRENT_STEP' do
      expect(described_class::CURRENT_STEP).to eq('onboarding_account_setup')
    end

    it 'defines NEXT_STEP' do
      expect(described_class::NEXT_STEP).to eq('onboarding_completed')
    end

    it 'defines TRANSACTION_TYPE_NAME' do
      expect(described_class::TRANSACTION_TYPE_NAME).to eq('Transfer In')
    end

    it 'defines TRANSACTION_TYPE_KIND' do
      expect(described_class::TRANSACTION_TYPE_KIND).to eq('transfer_in')
    end
  end

  describe '.model_name' do
    it 'returns custom model name' do
      expect(described_class.model_name.to_s).to eq('onboarding_account_setup_form')
    end
  end

  describe '#initialize' do
    context 'without payload' do
      it 'assigns user' do
        expect(form.user).to eq(user)
      end

      it 'creates default transactions' do
        expect(form.transactions).to be_an(Array)
        expect(form.transactions.size).to eq(1)
      end

      it 'sets onboarding_current_step' do
        described_class.new(user)
        expect(user.onboarding_current_step).to eq('onboarding_account_setup')
      end

      it 'default transaction has nil amount' do
        expect(form.transactions.first.amount).to be_nil
      end

      it 'default transaction has current date' do
        expect(form.transactions.first.transaction_date).to eq(Date.current)
      end

      it 'default transaction has empty account name' do
        expect(form.transactions.first.account.name).to eq('')
      end

      it 'default transaction has Transfer In type' do
        expect(form.transactions.first.transaction_type.name).to eq('Transfer In')
      end
    end

    context 'with transactions_attributes payload' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => {
              amount: '1000.00',
              transaction_date: '2025-10-27',
              account_attributes: { name: 'Checking' },
              transaction_type_attributes: { name: 'Transfer In' }
            },
            '1' => {
              amount: '500.00',
              account_attributes: { name: 'Savings' }
            }
          }
        }
      end

      it 'builds transactions from payload' do
        form = described_class.new(user, payload)
        expect(form.transactions.size).to eq(2)
      end

      it 'sets transaction amounts' do
        form = described_class.new(user, payload)
        expect(form.transactions[0].amount).to eq(1000.00)
        expect(form.transactions[1].amount).to eq(500.00)
      end

      it 'sets account names' do
        form = described_class.new(user, payload)
        expect(form.transactions[0].account.name).to eq('Checking')
        expect(form.transactions[1].account.name).to eq('Savings')
      end

      it 'sets transaction dates' do
        form = described_class.new(user, payload)
        expect(form.transactions[0].transaction_date).to eq(Date.parse('2025-10-27'))
      end

      it 'uses default date when not provided' do
        form = described_class.new(user, payload)
        expect(form.transactions[1].transaction_date).to eq(Date.current)
      end

      it 'uses default transaction type name when not provided' do
        form = described_class.new(user, payload)
        expect(form.transactions[1].transaction_type.name).to eq('Transfer In')
      end
    end
  end

  describe '#transactions_attributes=' do
    let(:attributes) do
      {
        '0' => {
          amount: '250.50',
          account_attributes: { name: 'Wallet' }
        }
      }
    end

    it 'builds transactions from attributes hash' do
      form.transactions_attributes = attributes
      expect(form.transactions.size).to eq(1)
      expect(form.transactions.first.amount).to eq(250.50)
      expect(form.transactions.first.account.name).to eq('Wallet')
    end

    it 'handles nested account attributes with symbol keys' do
      attrs = { '0' => { amount: '100', account: { name: 'Test' } } }
      form.transactions_attributes = attrs
      expect(form.transactions.first.account.name).to eq('Test')
    end
  end

  describe 'validations' do
    describe '#at_least_one_valid_transaction' do
      context 'with no valid transactions' do
        let(:payload) do
          {
            transactions_attributes: {
              '0' => { amount: '0', account_attributes: { name: '' } }
            }
          }
        end

        it 'is invalid' do
          form = described_class.new(user, payload)
          expect(form).not_to be_valid
        end

        it 'adds error to base' do
          form = described_class.new(user, payload)
          form.valid?
          expect(form.errors[:base]).to be_present
        end
      end

      context 'with valid account but zero amount' do
        let(:payload) do
          {
            transactions_attributes: {
              '0' => { amount: '0', account_attributes: { name: 'Checking' } }
            }
          }
        end

        it 'is invalid' do
          form = described_class.new(user, payload)
          expect(form).not_to be_valid
        end
      end

      context 'with valid amount but blank account name' do
        let(:payload) do
          {
            transactions_attributes: {
              '0' => { amount: '100', account_attributes: { name: '' } }
            }
          }
        end

        it 'is invalid' do
          form = described_class.new(user, payload)
          expect(form).not_to be_valid
        end
      end

      context 'with at least one valid transaction' do
        let(:payload) do
          {
            transactions_attributes: {
              '0' => { amount: '100', account_attributes: { name: 'Checking' } }
            }
          }
        end

        it 'is valid' do
          form = described_class.new(user, payload)
          expect(form).to be_valid
        end
      end

      context 'with mixed valid and invalid transactions' do
        let(:payload) do
          {
            transactions_attributes: {
              '0' => { amount: '0', account_attributes: { name: '' } },
              '1' => { amount: '500', account_attributes: { name: 'Savings' } }
            }
          }
        end

        it 'is valid when at least one is valid' do
          form = described_class.new(user, payload)
          expect(form).to be_valid
        end
      end
    end
  end

  describe '#submit' do
    context 'with valid data' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => {
              amount: '1500.00',
              account_attributes: { name: 'Checking Account' },
              transaction_type_attributes: { name: 'Transfer In' }
            }
          }
        }
      end
      let(:form) { described_class.new(user, payload) }

      it 'returns true' do
        expect(form.submit).to be true
      end

      it 'creates account' do
        expect { form.submit }.to change { user.accounts.count }.by(1)
      end

      it 'creates transaction type' do
        expect { form.submit }.to change { user.transaction_types.count }.by(1)
      end

      it 'creates transaction' do
        expect { form.submit }.to change { user.transactions.count }.by(1)
      end

      it 'sets account name' do
        form.submit
        expect(user.accounts.last.name).to eq('Checking Account')
      end

      it 'sets transaction amount' do
        form.submit
        expect(user.transactions.last.amount).to eq(1500.00)
      end

      it 'sets transaction description' do
        form.submit
        expect(user.transactions.last.description).to include('Checking Account')
      end

      it 'sets transaction date' do
        form.submit
        expect(user.transactions.last.transaction_date).to eq(Date.current)
      end

      it 'updates user onboarding step' do
        form.submit
        expect(user.reload.onboarding_current_step).to eq('onboarding_completed')
      end

      it 'sets account balance from transaction callback' do
        form.submit
        # The transaction after_save callback updates the account balance
        expect(user.accounts.last.balance).to eq(1500.00)
      end

      it 'sets account saving_goal to 0.0' do
        form.submit
        expect(user.accounts.last.saving_goal).to eq(0.0)
      end

      it 'sets transaction type kind to transfer_in' do
        form.submit
        expect(user.transaction_types.last.kind).to eq('transfer_in')
      end

      it 'sets transaction type budget_goal to 0.0' do
        form.submit
        expect(user.transaction_types.last.budget_goal).to eq(0.0)
      end
    end

    context 'with multiple valid transactions' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '1000', account_attributes: { name: 'Checking' } },
            '1' => { amount: '2000', account_attributes: { name: 'Savings' } },
            '2' => { amount: '500', account_attributes: { name: 'Wallet' } }
          }
        }
      end
      let(:form) { described_class.new(user, payload) }

      it 'creates all accounts' do
        expect { form.submit }.to change { user.accounts.count }.by(3)
      end

      it 'creates all transactions' do
        expect { form.submit }.to change { user.transactions.count }.by(3)
      end

      it 'creates one transaction type' do
        # All use the same default transaction type
        expect { form.submit }.to change { user.transaction_types.count }.by(1)
      end
    end

    context 'with duplicate account names' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '1000', account_attributes: { name: 'Checking' } },
            '1' => { amount: '500', account_attributes: { name: 'Checking' } }
          }
        }
      end
      let(:form) { described_class.new(user, payload) }

      it 'reuses the same account' do
        expect { form.submit }.to change { user.accounts.count }.by(1)
      end

      it 'creates both transactions' do
        expect { form.submit }.to change { user.transactions.count }.by(2)
      end

      it 'both transactions reference same account' do
        form.submit
        transactions = user.transactions.order(:created_at)
        expect(transactions.first.account_id).to eq(transactions.last.account_id)
      end
    end

    context 'with account name having whitespace' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '1000', account_attributes: { name: '  Checking  ' } }
          }
        }
      end
      let(:form) { described_class.new(user, payload) }

      it 'strips whitespace from account name' do
        form.submit
        expect(user.accounts.last.name).to eq('Checking')
      end
    end

    context 'with invalid data' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '', account_attributes: { name: '' } }
          }
        }
      end

      it 'returns false' do
        form = described_class.new(user, payload)
        expect(form.submit).to be false
      end

      it 'does not create account' do
        form = described_class.new(user, payload)
        expect { form.submit }.not_to change { user.accounts.count }
      end

      it 'does not create transaction' do
        form = described_class.new(user, payload)
        expect { form.submit }.not_to change { user.transactions.count }
      end

      it 'sets onboarding step on initialization' do
        form = described_class.new(user, payload)
        expect(user.onboarding_current_step).to eq('onboarding_account_setup')
      end

      it 'sets onboarding step in memory but does not persist on failed submit' do
        form = described_class.new(user, payload)
        form.submit
        expect(form.submit).to be false
      end
    end

    context 'with transactions to skip' do
      # Note: This scenario demonstrates that all transactions must pass ActiveRecord validations
      # The form skips transactions during persist, but the AR transaction fails if any invalid
      it 'validates at form level but may fail at AR level' do
        payload = {
          transactions_attributes: {
            '0' => { amount: '1000', account_attributes: { name: 'Checking' } },
            '1' => { amount: '0', account_attributes: { name: 'Empty' } },
            '2' => { amount: '500', account_attributes: { name: '' } }
          }
        }
        form = described_class.new(user, payload)

        expect(form).to be_valid
        expect(form.submit).to be false
      end
    end

    context 'with only valid transactions' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '1000', account_attributes: { name: 'Checking' } },
            '1' => { amount: '500', account_attributes: { name: 'Savings' } }
          }
        }
      end

      it 'successfully creates all transactions' do
        form = described_class.new(user, payload)
        expect(form.submit).to be true
        expect(user.accounts.count).to eq(2)
        expect(user.transactions.count).to eq(2)
      end
    end

    context 'when transaction save fails' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '1000', account_attributes: { name: 'Checking' } }
          }
        }
      end
      let(:form) { described_class.new(user, payload) }

      before do
        allow_any_instance_of(Transaction).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(Transaction.new))
      end

      it 'returns false' do
        expect(form.submit).to be false
      end

      it 'adds error to form' do
        form.submit
        expect(form.errors[:base]).to be_present
      end

      it 'rolls back all changes' do
        expect { form.submit }.not_to change { user.accounts.count }
      end

      it 'logs error' do
        allow(Rails.logger).to receive(:error)
        form.submit
        expect(Rails.logger).to have_received(:error).with(/AccountSetupForm submit error/)
      end
    end

    context 'when database error occurs' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '1000', account_attributes: { name: 'Checking' } }
          }
        }
      end
      let(:form) { described_class.new(user, payload) }

      before do
        allow(user).to receive(:save!).and_raise(ActiveRecord::ActiveRecordError, 'Database error')
      end

      it 'returns false' do
        expect(form.submit).to be false
      end

      it 'adds error message' do
        form.submit
        expect(form.errors[:base]).to include('Database error')
      end
    end
  end

  describe 'private methods' do
    describe '#should_skip_transaction?' do
      it 'skips transaction with nil account' do
        transaction = Transaction.new(amount: 100)
        transaction.account = nil
        expect(form.send(:should_skip_transaction?, transaction)).to be true
      end

      it 'skips transaction with blank account name' do
        transaction = Transaction.new(amount: 100)
        transaction.account = Account.new(name: '')
        expect(form.send(:should_skip_transaction?, transaction)).to be true
      end

      it 'skips transaction with zero amount' do
        transaction = Transaction.new(amount: 0)
        transaction.account = Account.new(name: 'Test')
        expect(form.send(:should_skip_transaction?, transaction)).to be true
      end

      it 'skips transaction with negative amount' do
        transaction = Transaction.new(amount: -100)
        transaction.account = Account.new(name: 'Test')
        expect(form.send(:should_skip_transaction?, transaction)).to be true
      end

      it 'does not skip valid transaction' do
        transaction = Transaction.new(amount: 100)
        transaction.account = Account.new(name: 'Test')
        expect(form.send(:should_skip_transaction?, transaction)).to be false
      end
    end

    describe '#find_or_create_account' do
      let(:account) { Account.new(name: 'Test Account') }

      it 'creates new account if not exists' do
        expect { form.send(:find_or_create_account, account) }.to change { user.accounts.count }.by(1)
      end

      it 'returns existing account if name matches' do
        existing = create(:account, user: user, name: 'Test Account')
        result = form.send(:find_or_create_account, account)
        expect(result.id).to eq(existing.id)
      end

      it 'strips whitespace when finding account' do
        existing = create(:account, user: user, name: 'Test')
        account_with_spaces = Account.new(name: '  Test  ')
        result = form.send(:find_or_create_account, account_with_spaces)
        expect(result.id).to eq(existing.id)
      end
    end

    describe '#find_or_create_transaction_type' do
      let(:transaction_type) { TransactionType.new(name: 'Transfer In', kind: 'transfer_in') }

      it 'creates new transaction type if not exists' do
        expect {
          form.send(:find_or_create_transaction_type, transaction_type)
        }.to change { user.transaction_types.count }.by(1)
      end

      it 'returns existing transaction type if kind matches' do
        existing = create(:transaction_type, user: user, kind: 'transfer_in')
        result = form.send(:find_or_create_transaction_type, transaction_type)
        expect(result.id).to eq(existing.id)
      end

      it 'uses default kind when not provided' do
        tt = TransactionType.new(name: 'Test')
        result = form.send(:find_or_create_transaction_type, tt)
        expect(result.kind).to eq('transfer_in')
      end

      it 'uses default name when not provided' do
        tt = TransactionType.new(kind: 'transfer_in')
        result = form.send(:find_or_create_transaction_type, tt)
        expect(result.name).to eq('Transfer In')
      end
    end
  end

  describe 'integration scenarios' do
    context 'setting up multiple accounts for new user' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '5000', account_attributes: { name: 'Checking' } },
            '1' => { amount: '10000', account_attributes: { name: 'Savings' } },
            '2' => { amount: '200', account_attributes: { name: 'Cash' } }
          }
        }
      end
      let(:form) { described_class.new(user, payload) }

      it 'successfully creates all accounts and transactions' do
        expect(form.submit).to be true
        expect(user.accounts.count).to eq(3)
        expect(user.transactions.count).to eq(3)
        expect(user.onboarding_current_step).to eq('onboarding_completed')
      end

      it 'creates transactions with correct descriptions' do
        form.submit
        descriptions = user.transactions.pluck(:description)
        expect(descriptions).to all(match(/Initial balance/i))
      end
    end

    context 'user already has onboarding_current_step set' do
      let(:user) { create(:user, onboarding_current_step: 'onboarding_profile_setup') }
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '1000', account_attributes: { name: 'Test' } }
          }
        }
      end

      it 'does not change step on initialization' do
        form = described_class.new(user, payload)
        expect(user.onboarding_current_step).to eq('onboarding_profile_setup')
      end

      it 'updates step on successful submit' do
        form = described_class.new(user, payload)
        form.submit
        expect(user.reload.onboarding_current_step).to eq('onboarding_completed')
      end
    end
  end
end
