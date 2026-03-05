# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::AccountSetupForm, type: :model do
  let(:user) { create(:user, onboarding_current_step: nil) }
  let(:space) { user.spaces.first }
  let(:form) { described_class.new(space) }

  describe 'constants' do
    it 'defines CURRENT_STEP' do
      expect(described_class::CURRENT_STEP).to eq('onboarding_account_setup')
    end

    it 'defines NEXT_STEP' do
      expect(described_class::NEXT_STEP).to eq('onboarding_completed')
    end
  end

  describe '.model_name' do
    it 'returns custom model name' do
      expect(described_class.model_name.to_s).to eq('onboarding_account_setup_form')
    end
  end

  describe '#initialize' do
    context 'without payload' do
      it 'assigns space' do
        expect(form.space).to eq(space)
      end

      it 'creates default transaction forms' do
        expect(form.transactions).to be_an(Array)
        expect(form.transactions.size).to eq(1)
        expect(form.transactions.first).to be_a(Onboarding::TransactionForm)
      end

      it 'sets onboarding_current_step' do
        described_class.new(space)
        expect(space.onboarding_current_step).to eq('onboarding_account_setup')
      end

      it 'default transaction form has nil amount' do
        expect(form.transactions.first.amount).to be_nil
      end

      it 'default transaction form has current date' do
        expect(form.transactions.first.transaction_date).to eq(Date.current)
      end

      it 'default transaction form has empty account name' do
        expect(form.transactions.first.account_name).to eq('')
      end

      it 'default transaction form has Transfer In type' do
        expect(form.transactions.first.transaction_type_name).to eq('Transfer In')
      end
    end

    context 'with transactions_attributes payload' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => {
              amount: '1000.00',
              transaction_date: '2025-10-27',
              account_name: 'Checking',
              transaction_type_name: 'Transfer In'
            },
            '1' => {
              amount: '500.00',
              account_name: 'Savings'
            }
          }
        }
      end

      it 'builds transaction forms from payload' do
        form = described_class.new(space, payload)
        expect(form.transactions.size).to eq(2)
      end

      it 'sets transaction amounts' do
        form = described_class.new(space, payload)
        expect(form.transactions[0].amount).to eq(1000.00)
        expect(form.transactions[1].amount).to eq(500.00)
      end

      it 'sets account names' do
        form = described_class.new(space, payload)
        expect(form.transactions[0].account_name).to eq('Checking')
        expect(form.transactions[1].account_name).to eq('Savings')
      end

      it 'sets transaction dates' do
        form = described_class.new(space, payload)
        expect(form.transactions[0].transaction_date).to eq(Date.parse('2025-10-27'))
      end

      it 'uses default date when not provided' do
        form = described_class.new(space, payload)
        expect(form.transactions[1].transaction_date).to eq(Date.current)
      end

      it 'uses default transaction type name when not provided' do
        form = described_class.new(space, payload)
        expect(form.transactions[1].transaction_type_name).to eq('Transfer In')
      end
    end
  end

  describe '#transactions_attributes=' do
    let(:attributes) do
      {
        '0' => {
          amount: '250.50',
          account_name: 'Wallet'
        }
      }
    end

    it 'builds transaction forms from attributes hash' do
      form.transactions_attributes = attributes
      expect(form.transactions.size).to eq(1)
      expect(form.transactions.first.amount).to eq(250.50)
      expect(form.transactions.first.account_name).to eq('Wallet')
    end
  end

  describe 'validations' do
    describe '#at_least_one_valid_transaction' do
      context 'with no valid transactions' do
        let(:payload) do
          {
            transactions_attributes: {
              '0' => { amount: '0', account_name: '' }
            }
          }
        end

        it 'is invalid' do
          form = described_class.new(space, payload)
          expect(form).not_to be_valid
        end

        it 'adds error to base' do
          form = described_class.new(space, payload)
          form.valid?
          expect(form.errors[:base]).to be_present
        end
      end

      context 'with valid account but zero amount' do
        let(:payload) do
          {
            transactions_attributes: {
              '0' => { amount: '0', account_name: 'Checking' }
            }
          }
        end

        it 'is invalid' do
          form = described_class.new(space, payload)
          expect(form).not_to be_valid
        end
      end

      context 'with valid amount but blank account name' do
        let(:payload) do
          {
            transactions_attributes: {
              '0' => { amount: '100', account_name: '' }
            }
          }
        end

        it 'is invalid' do
          form = described_class.new(space, payload)
          expect(form).not_to be_valid
        end
      end

      context 'with at least one valid transaction' do
        let(:payload) do
          {
            transactions_attributes: {
              '0' => { amount: '100', account_name: 'Checking' }
            }
          }
        end

        it 'is valid' do
          form = described_class.new(space, payload)
          expect(form).to be_valid
        end
      end

      context 'with mixed valid and invalid transactions' do
        let(:payload) do
          {
            transactions_attributes: {
              '0' => { amount: '0', account_name: '' },
              '1' => { amount: '500', account_name: 'Savings' }
            }
          }
        end

        it 'is valid when at least one is valid' do
          form = described_class.new(space, payload)
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
              account_name: 'Checking Account',
              transaction_type_name: 'Transfer In'
            }
          }
        }
      end
      let(:form) { described_class.new(space, payload) }

      it 'returns true' do
        expect(form.submit).to be true
      end

      it 'creates account' do
        expect { form.submit }.to change { space.accounts.count }.by(1)
      end

      it 'creates transaction type' do
        expect { form.submit }.to change { space.transaction_types.count }.by(1)
      end

      it 'creates transaction' do
        expect { form.submit }.to change { space.transactions.count }.by(1)
      end

      it 'sets account name' do
        form.submit
        expect(space.accounts.last.name).to eq('Checking Account')
      end

      it 'sets transaction amount' do
        form.submit
        expect(space.transactions.last.amount).to eq(1500.00)
      end

      it 'sets transaction date' do
        form.submit
        expect(space.transactions.last.transaction_date).to eq(Date.current)
      end

      it 'updates user onboarding step' do
        form.submit
        expect(space.reload.onboarding_current_step).to eq('onboarding_completed')
      end

      it 'sets account balance from transaction' do
        form.submit
        expect(space.accounts.last.balance).to eq(1500.00)
      end
    end

    context 'with multiple valid transactions' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '1000', account_name: 'Checking' },
            '1' => { amount: '2000', account_name: 'Savings' },
            '2' => { amount: '500', account_name: 'Wallet' }
          }
        }
      end
      let(:form) { described_class.new(space, payload) }

      it 'creates all accounts' do
        expect { form.submit }.to change { space.accounts.count }.by(3)
      end

      it 'creates all transactions' do
        expect { form.submit }.to change { space.transactions.count }.by(3)
      end

      it 'creates one transaction type' do
        expect { form.submit }.to change { space.transaction_types.count }.by(1)
      end
    end

    context 'with duplicate account names' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '1000', account_name: 'Checking' },
            '1' => { amount: '500', account_name: 'Checking' }
          }
        }
      end
      let(:form) { described_class.new(space, payload) }

      it 'reuses the same account' do
        expect { form.submit }.to change { space.accounts.count }.by(1)
      end

      it 'creates both transactions' do
        expect { form.submit }.to change { space.transactions.count }.by(2)
      end

      it 'both transactions reference same account' do
        form.submit
        transactions = space.transactions.order(:created_at)
        expect(transactions.first.account_id).to eq(transactions.last.account_id)
      end
    end

    context 'with invalid data' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '', account_name: '' }
          }
        }
      end

      it 'returns false' do
        form = described_class.new(space, payload)
        expect(form.submit).to be false
      end

      it 'does not create account' do
        form = described_class.new(space, payload)
        expect { form.submit }.not_to change { space.accounts.count }
      end

      it 'does not create transaction' do
        form = described_class.new(space, payload)
        expect { form.submit }.not_to change { space.transactions.count }
      end

      it 'does not update onboarding step' do
        form = described_class.new(space, payload)
        form.submit
        expect(space.reload.onboarding_current_step).to be_nil
      end
    end

    context 'with transactions to skip' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '1000', account_name: 'Checking' },
            '1' => { amount: '0', account_name: 'Empty' },
            '2' => { amount: '500', account_name: '' }
          }
        }
      end

      it 'skips invalid transactions and creates only valid ones' do
        form = described_class.new(space, payload)
        expect(form.submit).to be true
        expect(space.accounts.count).to eq(1)
        expect(space.transactions.count).to eq(1)
      end
    end

    context 'when transaction form fails' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '1000', account_name: 'Checking' }
          }
        }
      end
      let(:form) { described_class.new(space, payload) }

      before do
        allow_any_instance_of(Onboarding::TransactionForm).to receive(:should_skip?).and_return(false)
        allow_any_instance_of(Onboarding::TransactionForm).to receive(:submit).and_return(false)
        allow_any_instance_of(Onboarding::TransactionForm).to receive(:errors).and_return(
          double(messages: { base: [ 'Transaction error' ] })
        )
      end

      it 'returns false' do
        expect(form.submit).to be false
      end

      it 'does not create account' do
        expect { form.submit }.not_to change { space.accounts.count }
      end

      it 'promotes errors from transaction form' do
        form.submit
        expect(form.errors[:base]).to be_present
      end
    end

    context 'when database error occurs' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '1000', account_name: 'Checking' }
          }
        }
      end
      let(:form) { described_class.new(space, payload) }

      before do
        allow(space).to receive(:save!).and_raise(ActiveRecord::ActiveRecordError, 'Database error')
      end

      it 'returns false' do
        expect(form.submit).to be false
      end

      it 'adds error message' do
        form.submit
        expect(form.errors[:base]).to include('Database error')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/AccountSetupForm submit error/)
        form.submit
      end
    end
  end

  describe 'integration scenarios' do
    context 'setting up multiple accounts for new user' do
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '5000', account_name: 'Checking' },
            '1' => { amount: '10000', account_name: 'Savings' },
            '2' => { amount: '200', account_name: 'Cash' }
          }
        }
      end
      let(:form) { described_class.new(space, payload) }

      it 'successfully creates all accounts and transactions' do
        expect(form.submit).to be true
        expect(space.accounts.count).to eq(3)
        expect(space.transactions.count).to eq(3)
        expect(space.onboarding_current_step).to eq('onboarding_completed')
      end
    end

    context 'user already has onboarding_current_step set' do
      let(:user) { create(:user, onboarding_current_step: 'onboarding_profile_setup') }
      let(:payload) do
        {
          transactions_attributes: {
            '0' => { amount: '1000', account_name: 'Test' }
          }
        }
      end

      it 'does not change step on initialization' do
        form = described_class.new(space, payload)
        expect(space.onboarding_current_step).to eq('onboarding_profile_setup')
      end

      it 'updates step on successful submit' do
        form = described_class.new(space, payload)
        form.submit
        expect(space.reload.onboarding_current_step).to eq('onboarding_completed')
      end
    end
  end
end
