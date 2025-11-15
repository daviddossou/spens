# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoalForm, type: :model do
  let(:user) { create(:user) }
  let(:valid_attributes) do
    {
      account_name: 'Emergency Fund',
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
      expect(form.account_name).to eq('Emergency Fund')
    end

    it 'sets current_balance from payload' do
      expect(form.current_balance).to eq(1000.00)
    end

    it 'sets saving_goal from payload' do
      expect(form.saving_goal).to eq(5000.00)
    end

    context 'with empty payload' do
      let(:form) { described_class.new(user, {}) }

      it 'initializes with nil values' do
        expect(form.account_name).to be_nil
        expect(form.current_balance).to be_nil
        expect(form.saving_goal).to be_nil
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

      it 'is valid with non-numeric current_balance that converts to zero' do
        # ActiveModel::Type::Decimal converts non-numeric strings to 0
        form.current_balance = 'abc'
        form.saving_goal = 100
        expect(form).to be_valid
        expect(form.current_balance).to eq(0)
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
      it 'is valid with saving_goal present' do
        expect(form).to be_valid
      end

      it 'is invalid without saving_goal' do
        form.saving_goal = nil
        expect(form).not_to be_valid
        expect(form.errors[:saving_goal]).to include("can't be blank")
      end

      it 'is invalid with non-numeric saving_goal that converts to zero' do
        # ActiveModel::Type::Decimal converts non-numeric strings to 0
        form.saving_goal = 'xyz'
        expect(form).not_to be_valid
        expect(form.errors[:saving_goal]).to include("must be greater than 0")
      end

      it 'is invalid with zero saving_goal' do
        form.saving_goal = 0
        expect(form).not_to be_valid
        expect(form.errors[:saving_goal]).to include("must be greater than 0")
      end

      it 'is invalid with negative saving_goal' do
        form.saving_goal = -100
        expect(form).not_to be_valid
        expect(form.errors[:saving_goal]).to include("must be greater than 0")
      end

      it 'is valid with positive saving_goal' do
        form.saving_goal = 5000
        expect(form).to be_valid
      end
    end

    context 'saving_goal_greater_than_balance validation' do
      it 'is valid when saving_goal is greater than current_balance' do
        form.current_balance = 1000
        form.saving_goal = 5000
        expect(form).to be_valid
      end

      it 'is invalid when saving_goal equals current_balance' do
        form.current_balance = 5000
        form.saving_goal = 5000
        expect(form).not_to be_valid
        expect(form.errors[:saving_goal]).to include(I18n.t('errors.messages.goal_must_be_greater'))
      end

      it 'is invalid when saving_goal is less than current_balance' do
        form.current_balance = 5000
        form.saving_goal = 1000
        expect(form).not_to be_valid
        expect(form.errors[:saving_goal]).to include(I18n.t('errors.messages.goal_must_be_greater'))
      end

      it 'does not validate when current_balance is nil' do
        form.current_balance = nil
        form.saving_goal = 5000
        expect(form).not_to be_valid
        expect(form.errors[:saving_goal]).not_to include(I18n.t('errors.messages.goal_must_be_greater'))
      end

      it 'does not validate when saving_goal is nil' do
        form.current_balance = 1000
        form.saving_goal = nil
        expect(form).not_to be_valid
        expect(form.errors[:saving_goal]).not_to include(I18n.t('errors.messages.goal_must_be_greater'))
      end
    end
  end

  describe '.model_name' do
    it 'returns ActiveModel::Name for Goal' do
      expect(described_class.model_name.name).to eq('Goal')
      expect(described_class.model_name.param_key).to eq('goal')
      expect(described_class.model_name.route_key).to eq('goals')
    end
  end

  describe '#persisted?' do
    it 'always returns false' do
      expect(form.persisted?).to be(false)
    end
  end

  describe '#to_model' do
    it 'returns self' do
      expect(form.to_model).to eq(form)
    end
  end

  describe '#account_suggestions' do
    let!(:account1) { create(:account, user: user, name: 'Savings') }
    let!(:account2) { create(:account, user: user, name: 'Checking') }

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
      end

      it 'does not create or update account' do
        form.saving_goal = 0
        expect { form.submit }.not_to change { Account.count }
      end
    end

    context 'with valid form and new account' do
      let(:account) { create(:account, user: user, name: 'Emergency Fund', balance: 0) }

      before do
        allow(FindOrCreateAccountService).to receive(:new).with(user, 'Emergency Fund')
          .and_return(instance_double(FindOrCreateAccountService, call: account))
      end

      it 'calls FindOrCreateAccountService' do
        expect(FindOrCreateAccountService).to receive(:new).with(user, 'Emergency Fund').and_call_original
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
        let(:account) { create(:account, user: user, name: 'Emergency Fund', balance: 1000) }

        it 'does not create adjustment transaction' do
          expect(CreateTransactionService).not_to receive(:new)
          form.submit
        end

        it 'updates saving_goal only' do
          form.submit
          expect(account.reload.saving_goal).to eq(5000.00)
          expect(account.reload.balance).to eq(1000.00)
        end
      end

      context 'when current_balance is higher than account balance' do
        let(:account) { create(:account, user: user, name: 'Emergency Fund', balance: 500) }
        let(:transaction_type) { create(:transaction_type, user: user, kind: TransactionType::KIND_TRANSFER_IN) }

        before do
          allow(FindOrCreateTransactionTypeService).to receive(:new)
            .with(user, I18n.t('transactions.transfer.type_name.transfer_in'), TransactionType::KIND_TRANSFER_IN)
            .and_return(instance_double(FindOrCreateTransactionTypeService, call: transaction_type))
        end

        it 'creates transfer_in transaction for the difference' do
          expect(CreateTransactionService).to receive(:new).with(
            user,
            account,
            transaction_type,
            500.0,
            Date.current,
            nil,
            transaction_type.name
          ).and_call_original

          form.submit
        end

        it 'adjusts account balance' do
          allow_any_instance_of(CreateTransactionService).to receive(:call) do
            account.update!(balance: account.balance + 500)
          end

          form.submit
          expect(account.reload.balance).to eq(1000.00)
        end
      end

      context 'when current_balance is lower than account balance' do
        let(:account) { create(:account, user: user, name: 'Emergency Fund', balance: 1500) }
        let(:transaction_type) { create(:transaction_type, user: user, kind: TransactionType::KIND_TRANSFER_OUT) }

        before do
          allow(FindOrCreateTransactionTypeService).to receive(:new)
            .with(user, I18n.t('transactions.transfer.type_name.transfer_out'), TransactionType::KIND_TRANSFER_OUT)
            .and_return(instance_double(FindOrCreateTransactionTypeService, call: transaction_type))
        end

        it 'creates transfer_out transaction for the difference' do
          expect(CreateTransactionService).to receive(:new).with(
            user,
            account,
            transaction_type,
            500.0,
            Date.current,
            nil,
            transaction_type.name
          ).and_call_original

          form.submit
        end

        it 'adjusts account balance' do
          allow_any_instance_of(CreateTransactionService).to receive(:call) do
            account.update!(balance: account.balance - 500)
          end

          form.submit
          expect(account.reload.balance).to eq(1000.00)
        end
      end
    end

    context 'when ActiveRecord transaction fails' do
      let(:account) { create(:account, user: user, name: 'Emergency Fund') }

      before do
        allow(FindOrCreateAccountService).to receive(:new).with(user, 'Emergency Fund')
          .and_return(instance_double(FindOrCreateAccountService, call: account))
        allow(account).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(account))
      end

      it 'returns false' do
        expect(form.submit).to be(false)
      end

      it 'adds error to base' do
        form.submit
        expect(form.errors[:base]).to be_present
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/GoalForm submit error/)
        form.submit
      end
    end

    context 'when service raises StandardError' do
      before do
        allow(FindOrCreateAccountService).to receive(:new).and_raise(StandardError, "Service error")
      end

      it 'returns false' do
        expect(form.submit).to be(false)
      end

      it 'adds custom error to base' do
        form.submit
        expect(form.errors[:base]).to include("Service error")
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/GoalForm submit error: Service error/)
        form.submit
      end
    end

    context 'edge cases' do
      let(:account) { create(:account, user: user, name: 'Test Account', balance: 0) }

      before do
        allow(FindOrCreateAccountService).to receive(:new).with(user, form.account_name)
          .and_return(instance_double(FindOrCreateAccountService, call: account))
      end

      it 'handles very large amounts' do
        form.current_balance = 999_999_999.99
        form.saving_goal = 1_000_000_000.00
        expect(form.submit).to eq(account)
      end

      it 'handles decimal precision correctly' do
        form.current_balance = 100.12345
        form.saving_goal = 200.67890
        expect(form.submit).to eq(account)
        expect(account.reload.saving_goal).to eq(200.67890)
      end

      it 'handles account names with special characters' do
        form.account_name = "John's Emergency Fund (💰)"
        allow(FindOrCreateAccountService).to receive(:new).with(user, "John's Emergency Fund (💰)")
          .and_return(instance_double(FindOrCreateAccountService, call: account))
        expect(form.submit).to eq(account)
      end

      it 'handles very small balance differences' do
        account.update!(balance: 1000.01)
        form.current_balance = 1000.02
        form.saving_goal = 2000.00

        transaction_type = create(:transaction_type, user: user, kind: TransactionType::KIND_TRANSFER_IN)
        allow(FindOrCreateTransactionTypeService).to receive(:new).and_return(double(call: transaction_type))

        # Due to floating point arithmetic, we need to use be_within matcher
        expect(CreateTransactionService).to receive(:new) do |u, acc, tt, amount, date, desc, name|
          expect(u).to eq(user)
          expect(acc).to eq(account)
          expect(tt).to eq(transaction_type)
          expect(amount).to be_within(0.001).of(0.01)
          expect(date).to eq(Date.current)
          expect(desc).to be_nil
          expect(name).to eq(transaction_type.name)
          instance_double(FindOrCreateTransactionTypeService, call: true)
        end

        form.submit
      end
    end
  end

  describe 'ActiveRecord transaction rollback' do
    let(:account) { create(:account, user: user, name: 'Emergency Fund', balance: 500) }
    let(:transaction_type) { create(:transaction_type, user: user, kind: TransactionType::KIND_TRANSFER_IN) }

    before do
      allow(FindOrCreateAccountService).to receive(:new).with(user, 'Emergency Fund')
        .and_return(instance_double(FindOrCreateAccountService, call: account))
      allow(FindOrCreateTransactionTypeService).to receive(:new)
        .and_return(instance_double(FindOrCreateTransactionTypeService, call: transaction_type))
      allow_any_instance_of(CreateTransactionService).to receive(:call)
        .and_raise(ActiveRecord::RecordInvalid.new(account))
    end

    it 'rolls back account update when transaction creation fails' do
      original_goal = account.saving_goal
      form.submit
      expect(account.reload.saving_goal).to eq(original_goal)
    end

    it 'returns false on rollback' do
      expect(form.submit).to be(false)
    end
  end
end
