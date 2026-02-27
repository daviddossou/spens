# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountForm, type: :model do
  let(:user) { create(:user) }
  let(:valid_attributes) do
    {
      account_name: 'My Savings',
      current_balance: 1000.00,
      saving_goal: 5000.00
    }
  end
  let(:form) { described_class.new(user, valid_attributes) }

  describe 'inheritance' do
    it 'inherits from BaseForm' do
      expect(described_class.superclass).to eq(BaseForm)
    end
  end

  describe '#initialize' do
    it 'sets the user attribute' do
      expect(form.user).to eq(user)
    end

    it 'sets account_name from payload' do
      expect(form.account_name).to eq('My Savings')
    end

    it 'sets current_balance from payload' do
      expect(form.current_balance).to eq(1000.00)
    end

    it 'sets saving_goal from payload' do
      expect(form.saving_goal).to eq(5000.00)
    end

    context 'with empty payload' do
      let(:form) { described_class.new(user, {}) }

      it 'initializes with nil/default values' do
        expect(form.account_name).to be_nil
        expect(form.current_balance).to be_nil
        expect(form.saving_goal).to eq(0.0)
      end
    end

    context 'with id in payload' do
      let!(:account) { create(:account, user: user, name: 'Existing') }
      let(:form) { described_class.new(user, valid_attributes.merge(id: account.id)) }

      it 'sets the account' do
        expect(form.account).to eq(account)
      end

      it 'is persisted' do
        expect(form.persisted?).to be(true)
      end
    end
  end

  describe 'validations' do
    context 'account_name' do
      it 'is valid with account_name present' do
        expect(form).to be_valid
      end

      it 'is invalid without account_name' do
        form.account_name = nil
        expect(form).not_to be_valid
        expect(form.errors[:account_name]).to include("can't be blank")
      end

      it 'is invalid with empty account_name' do
        form.account_name = ''
        expect(form).not_to be_valid
        expect(form.errors[:account_name]).to include("can't be blank")
      end

      it 'is invalid with account_name longer than 100 characters' do
        form.account_name = 'a' * 101
        expect(form).not_to be_valid
        expect(form.errors[:account_name]).to be_present
      end
    end

    context 'current_balance' do
      it 'is valid with current_balance present' do
        expect(form).to be_valid
      end

      it 'is invalid without current_balance' do
        form.current_balance = nil
        expect(form).not_to be_valid
        expect(form.errors[:current_balance]).to include("can't be blank")
      end

      it 'is valid with zero current_balance' do
        form.current_balance = 0
        expect(form).to be_valid
      end

      it 'is valid with negative current_balance' do
        form.current_balance = -100
        expect(form).to be_valid
      end
    end

    context 'saving_goal' do
      it 'is valid with zero saving_goal' do
        form.saving_goal = 0
        expect(form).to be_valid
      end

      it 'is valid with positive saving_goal' do
        form.saving_goal = 5000
        expect(form).to be_valid
      end

      it 'is invalid with negative saving_goal' do
        form.saving_goal = -100
        expect(form).not_to be_valid
        expect(form.errors[:saving_goal]).to be_present
      end

      it 'is valid with nil saving_goal (defaults to 0)' do
        form.saving_goal = nil
        expect(form).to be_valid
      end
    end
  end

  describe '.model_name' do
    it 'returns ActiveModel::Name for Account' do
      expect(described_class.model_name.name).to eq('Account')
      expect(described_class.model_name.param_key).to eq('account')
      expect(described_class.model_name.route_key).to eq('accounts')
    end
  end

  describe '#persisted?' do
    it 'returns false when no account' do
      expect(form.persisted?).to be(false)
    end

    it 'returns true when account present' do
      account = create(:account, user: user)
      form_with_account = described_class.new(user, valid_attributes.merge(id: account.id))
      expect(form_with_account.persisted?).to be(true)
    end
  end

  describe '#to_model' do
    it 'returns self' do
      expect(form.to_model).to eq(form)
    end
  end

  describe '#account_suggestions' do
    before do
      allow_any_instance_of(AccountSuggestionsService).to receive(:all_with_balances)
        .and_return([
          { name: 'Savings', balance: 1000 },
          { name: 'Checking', balance: 500 }
        ])
    end

    it 'calls AccountSuggestionsService with user' do
      expect(AccountSuggestionsService).to receive(:new).with(user).and_call_original
      form.account_suggestions
    end

    it 'returns all account suggestions with balances' do
      expect(form.account_suggestions).to eq([
        { name: 'Savings', balance: 1000 },
        { name: 'Checking', balance: 500 }
      ])
    end
  end

  describe '#default_account_suggestions' do
    before do
      allow_any_instance_of(AccountSuggestionsService).to receive(:defaults_with_balances)
        .and_return([
          { name: 'Emergency Fund', balance: 0 },
          { name: 'Vacation', balance: 0 }
        ])
    end

    it 'calls AccountSuggestionsService with user' do
      expect(AccountSuggestionsService).to receive(:new).with(user).and_call_original
      form.default_account_suggestions
    end

    it 'returns default account suggestions with balances' do
      expect(form.default_account_suggestions).to eq([
        { name: 'Emergency Fund', balance: 0 },
        { name: 'Vacation', balance: 0 }
      ])
    end
  end

  describe '#submit' do
    context 'with invalid form' do
      it 'returns false when validation fails' do
        form.account_name = nil
        expect(form.submit).to be(false)
        expect(form.errors[:account_name]).to include("can't be blank")
      end

      it 'does not create account' do
        form.account_name = nil
        expect { form.submit }.not_to change { Account.count }
      end
    end

    context 'creating a new account' do
      let(:account) { create(:account, user: user, name: 'My Savings', balance: 0) }

      before do
        allow(FindOrCreateAccountService).to receive(:new).with(user, 'My Savings')
          .and_return(instance_double(FindOrCreateAccountService, call: account))
      end

      it 'calls FindOrCreateAccountService' do
        expect(FindOrCreateAccountService).to receive(:new).with(user, 'My Savings').and_call_original
        form.submit
      end

      it 'updates the account saving_goal' do
        form.submit
        expect(account.reload.saving_goal).to eq(5000.00)
      end

      it 'returns the account' do
        expect(form.submit).to eq(account)
      end

      context 'when current_balance matches account balance' do
        let(:account) { create(:account, user: user, name: 'My Savings', balance: 1000) }

        it 'does not create adjustment transaction' do
          form.submit
          expect(account.transactions.count).to eq(0)
        end
      end

      context 'when current_balance is higher than account balance' do
        let(:account) { create(:account, user: user, name: 'My Savings', balance: 500) }

        it 'creates a transaction to adjust the balance' do
          expect { form.submit }.to change { account.transactions.count }.by(1)

          transaction = account.transactions.order(:created_at).last
          expect(transaction.amount).to eq(500.0)
          expect(transaction.transaction_type.kind).to eq(TransactionType::KIND_TRANSFER_IN)
        end

        it 'adjusts account balance' do
          form.submit
          expect(account.reload.balance).to eq(1000.00)
        end
      end

      context 'when current_balance is lower than account balance' do
        let(:account) { create(:account, user: user, name: 'My Savings', balance: 1500) }

        it 'creates a transaction to adjust the balance' do
          expect { form.submit }.to change { account.transactions.count }.by(1)

          transaction = account.transactions.order(:created_at).last
          expect(transaction.amount.abs).to eq(500.0)
          expect(transaction.transaction_type.kind).to eq(TransactionType::KIND_TRANSFER_OUT)
        end

        it 'adjusts account balance' do
          form.submit
          expect(account.reload.balance).to eq(1000.00)
        end
      end
    end

    context 'updating an existing account' do
      let!(:account) { create(:account, user: user, name: 'Old Name', balance: 500, saving_goal: 2000) }
      let(:update_attributes) do
        {
          id: account.id,
          account_name: 'New Name',
          current_balance: 800.00,
          saving_goal: 3000.00
        }
      end
      let(:update_form) { described_class.new(user, update_attributes) }

      it 'updates the account name' do
        update_form.submit
        expect(account.reload.name).to eq('New Name')
      end

      it 'updates the saving_goal' do
        update_form.submit
        expect(account.reload.saving_goal).to eq(3000.00)
      end

      it 'creates adjustment transaction for balance change' do
        expect { update_form.submit }.to change { account.transactions.count }.by(1)
      end

      it 'adjusts account balance' do
        update_form.submit
        expect(account.reload.balance).to eq(800.00)
      end

      context 'when balance unchanged' do
        let(:update_attributes) do
          {
            id: account.id,
            account_name: 'New Name',
            current_balance: 500.00,
            saving_goal: 3000.00
          }
        end

        it 'does not create adjustment transaction' do
          expect { update_form.submit }.not_to change { Transaction.count }
        end
      end
    end

    context 'when ActiveRecord transaction fails' do
      before do
        allow(FindOrCreateAccountService).to receive(:new)
          .and_raise(StandardError, "Service error")
      end

      it 'returns false' do
        expect(form.submit).to be(false)
      end

      it 'adds error to base' do
        form.submit
        expect(form.errors[:base]).to include("Service error")
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/AccountForm submit error: Service error/)
        form.submit
      end
    end
  end
end
