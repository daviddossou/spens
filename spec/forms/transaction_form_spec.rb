# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransactionForm, type: :model do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, name: 'Checking') }
  let(:valid_expense_attributes) do
    {
      kind: 'expense',
      account_name: 'Checking',
      amount: 100.00,
      transaction_date: Date.current,
      transaction_type_name: 'Groceries',
      note: 'Weekly shopping'
    }
  end
  let(:form) { described_class.new(user, valid_expense_attributes) }

  describe 'inheritance' do
    it 'inherits from BaseForm' do
      expect(described_class.superclass).to eq(BaseForm)
    end
  end

  describe 'validations' do
    context 'kind' do
      it 'is valid with expense kind' do
        form.kind = 'expense'
        expect(form).to be_valid
      end

      it 'is valid with income kind' do
        form.kind = 'income'
        expect(form).to be_valid
      end

      it 'is valid with transfer kind' do
        form.kind = 'transfer'
        form.from_account_name = 'Checking'
        form.to_account_name = 'Savings'
        expect(form).to be_valid
      end

      it 'is valid with loan kind' do
        form.kind = 'loan'
        expect(form).to be_valid
      end

      it 'is valid with debt kind' do
        form.kind = 'debt'
        expect(form).to be_valid
      end

      it 'is invalid without kind' do
        form.kind = nil
        expect(form).not_to be_valid
        expect(form.errors[:kind]).to include("can't be blank")
      end

      it 'is invalid with invalid kind' do
        form.kind = 'invalid'
        expect(form).not_to be_valid
        expect(form.errors[:kind]).to include("is not included in the list")
      end
    end

    context 'amount' do
      it 'is valid with positive amount' do
        form.amount = 100
        expect(form).to be_valid
      end

      it 'is invalid without amount' do
        form.amount = nil
        expect(form).not_to be_valid
        expect(form.errors[:amount]).to include("can't be blank")
      end

      it 'is invalid with zero amount' do
        form.amount = 0
        expect(form).not_to be_valid
        expect(form.errors[:amount]).to include("must be greater than 0")
      end

      it 'is invalid with negative amount' do
        form.amount = -50
        expect(form).not_to be_valid
        expect(form.errors[:amount]).to include("must be greater than 0")
      end
    end

    context 'transaction_date' do
      it 'is valid with present date' do
        form.transaction_date = Date.current
        expect(form).to be_valid
      end

      it 'is invalid without transaction_date' do
        form.transaction_date = nil
        expect(form).not_to be_valid
        expect(form.errors[:transaction_date]).to include("can't be blank")
      end

      it 'is valid with past date' do
        form.transaction_date = 1.week.ago.to_date
        expect(form).to be_valid
      end

      it 'is valid with future date' do
        form.transaction_date = 1.week.from_now.to_date
        expect(form).to be_valid
      end
    end

    context 'for non-transfer transactions' do
      %w[expense income loan debt].each do |kind|
        context "when kind is #{kind}" do
          before do
            form.kind = kind
            form.account_name = 'Checking'
            form.transaction_type_name = 'Test Category'
          end

          it 'requires account_name' do
            form.account_name = nil
            expect(form).not_to be_valid
            expect(form.errors[:account_name]).to include("can't be blank")
          end

          it 'requires transaction_type_name' do
            form.transaction_type_name = nil
            expect(form).not_to be_valid
            expect(form.errors[:transaction_type_name]).to include("can't be blank")
          end

          it 'does not require from_account_name' do
            form.from_account_name = nil
            expect(form).to be_valid
          end

          it 'does not require to_account_name' do
            form.to_account_name = nil
            expect(form).to be_valid
          end
        end
      end
    end

    context 'for transfer transactions' do
      before do
        form.kind = 'transfer'
        form.from_account_name = 'Checking'
        form.to_account_name = 'Savings'
      end

      it 'requires from_account_name' do
        form.from_account_name = nil
        expect(form).not_to be_valid
        expect(form.errors[:from_account_name]).to include("can't be blank")
      end

      it 'requires to_account_name' do
        form.to_account_name = nil
        expect(form).not_to be_valid
        expect(form.errors[:to_account_name]).to include("can't be blank")
      end

      it 'does not require account_name' do
        form.account_name = nil
        expect(form).to be_valid
      end

      it 'does not require transaction_type_name' do
        form.transaction_type_name = nil
        expect(form).to be_valid
      end

      context 'different_accounts_for_transfer validation' do
        it 'is valid when accounts are different' do
          form.from_account_name = 'Checking'
          form.to_account_name = 'Savings'
          expect(form).to be_valid
        end

        it 'is invalid when accounts are the same' do
          form.from_account_name = 'Checking'
          form.to_account_name = 'Checking'
          expect(form).not_to be_valid
          expect(form.errors[:to_account_name]).to include(I18n.t('errors.messages.different_account'))
        end

        it 'is invalid when accounts are the same (case insensitive)' do
          form.from_account_name = 'checking'
          form.to_account_name = 'CHECKING'
          expect(form).not_to be_valid
          expect(form.errors[:to_account_name]).to include(I18n.t('errors.messages.different_account'))
        end

        it 'is invalid when accounts are the same (with whitespace)' do
          form.from_account_name = '  Checking  '
          form.to_account_name = 'Checking'
          expect(form).not_to be_valid
          expect(form.errors[:to_account_name]).to include(I18n.t('errors.messages.different_account'))
        end

        it 'does not validate when from_account_name is missing' do
          form.from_account_name = nil
          form.to_account_name = 'Savings'
          expect(form).not_to be_valid
          expect(form.errors[:to_account_name]).not_to include(I18n.t('errors.messages.different_account'))
        end

        it 'does not validate when to_account_name is missing' do
          form.from_account_name = 'Checking'
          form.to_account_name = nil
          expect(form).not_to be_valid
          expect(form.errors[:to_account_name]).not_to include(I18n.t('errors.messages.different_account'))
        end
      end
    end
  end

  describe '#initialize' do
    it 'sets the user attribute' do
      expect(form.user).to eq(user)
    end

    context 'with basic payload' do
      it 'sets all attributes from payload' do
        expect(form.kind).to eq('expense')
        expect(form.account_name).to eq('Checking')
        expect(form.amount).to eq(100.00)
        expect(form.transaction_date).to eq(Date.current)
        expect(form.transaction_type_name).to eq('Groceries')
        expect(form.note).to eq('Weekly shopping')
      end
    end

    context 'with account_id in payload' do
      let(:payload) do
        {
          account_id: account.id,
          kind: 'expense',
          amount: 50.00,
          transaction_type_name: 'Food'
        }
      end
      let(:form) { described_class.new(user, payload) }

      it 'sets account_id' do
        expect(form.account_id).to eq(account.id)
      end

      it 'sets account_name from the found account' do
        expect(form.account_name).to eq('Checking')
      end

      it 'does not override explicit account_name' do
        payload[:account_name] = 'Savings'
        form = described_class.new(user, payload)
        expect(form.account_name).to eq('Savings')
      end

      context 'for transfer kind' do
        it 'sets to_account_name from the found account' do
          payload[:kind] = 'transfer'
          payload[:from_account_name] = 'Savings'
          form = described_class.new(user, payload)
          expect(form.to_account_name).to eq('Checking')
        end

        it 'does not override explicit to_account_name' do
          payload[:kind] = 'transfer'
          payload[:from_account_name] = 'Savings'
          payload[:to_account_name] = 'Investment'
          form = described_class.new(user, payload)
          expect(form.to_account_name).to eq('Investment')
        end
      end

      context 'when account_id does not belong to user' do
        let(:other_user) { create(:user) }
        let(:other_account) { create(:account, user: other_user) }

        it 'does not set account_name' do
          payload[:account_id] = other_account.id
          form = described_class.new(user, payload)
          expect(form.account_name).to be_nil
        end
      end

      context 'when account_id is invalid' do
        it 'does not set account_name' do
          payload[:account_id] = 'invalid-id'
          form = described_class.new(user, payload)
          expect(form.account_name).to be_nil
        end
      end
    end

    context 'with empty payload' do
      let(:form) { described_class.new(user, {}) }

      it 'sets default kind to expense' do
        expect(form.kind).to eq('expense')
      end

      it 'sets default transaction_date to current date' do
        expect(form.transaction_date).to eq(Date.current)
      end

      it 'initializes other attributes as nil' do
        expect(form.account_name).to be_nil
        expect(form.amount).to be_nil
        expect(form.transaction_type_name).to be_nil
        expect(form.note).to be_nil
      end
    end
  end

  describe '.model_name' do
    it 'returns ActiveModel::Name for Transaction' do
      expect(described_class.model_name.name).to eq('Transaction')
      expect(described_class.model_name.param_key).to eq('transaction')
      expect(described_class.model_name.route_key).to eq('transactions')
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

  describe '#transaction_type_suggestions' do
    before do
      allow_any_instance_of(TransactionTypeSuggestionsService).to receive(:all)
        .and_return(['Groceries', 'Rent', 'Utilities'])
    end

    it 'calls TransactionTypeSuggestionsService with user and kind' do
      expect(TransactionTypeSuggestionsService).to receive(:new).with(user, 'expense').and_call_original
      form.transaction_type_suggestions
    end

    it 'returns all transaction type suggestions' do
      expect(form.transaction_type_suggestions).to eq(['Groceries', 'Rent', 'Utilities'])
    end
  end

  describe '#default_transaction_type_suggestions' do
    before do
      allow_any_instance_of(TransactionTypeSuggestionsService).to receive(:defaults)
        .and_return(['Food', 'Transport', 'Entertainment'])
    end

    it 'calls TransactionTypeSuggestionsService with user and kind' do
      expect(TransactionTypeSuggestionsService).to receive(:new).with(user, 'expense').and_call_original
      form.default_transaction_type_suggestions
    end

    it 'returns default transaction type suggestions' do
      expect(form.default_transaction_type_suggestions).to eq(['Food', 'Transport', 'Entertainment'])
    end
  end

  describe '#account_suggestions' do
    before do
      allow_any_instance_of(AccountSuggestionsService).to receive(:all)
        .and_return(['Checking', 'Savings', 'Investment'])
    end

    it 'calls AccountSuggestionsService with user' do
      expect(AccountSuggestionsService).to receive(:new).with(user).and_call_original
      form.account_suggestions
    end

    it 'returns all account suggestions' do
      expect(form.account_suggestions).to eq(['Checking', 'Savings', 'Investment'])
    end
  end

  describe '#default_account_suggestions' do
    before do
      allow_any_instance_of(AccountSuggestionsService).to receive(:defaults)
        .and_return(['Wallet', 'Bank Account'])
    end

    it 'calls AccountSuggestionsService with user' do
      expect(AccountSuggestionsService).to receive(:new).with(user).and_call_original
      form.default_account_suggestions
    end

    it 'returns default account suggestions' do
      expect(form.default_account_suggestions).to eq(['Wallet', 'Bank Account'])
    end
  end

  describe '#kind_params' do
    context 'without account_id' do
      let(:form) { described_class.new(user, valid_expense_attributes) }

      it 'returns hash with only kind' do
        expect(form.kind_params('income')).to eq({ kind: 'income' })
      end
    end

    context 'with account_id' do
      let(:form) { described_class.new(user, valid_expense_attributes.merge(account_id: account.id)) }

      it 'returns hash with kind and account_id' do
        expect(form.kind_params('income')).to eq({ kind: 'income', account_id: account.id })
      end
    end
  end

  describe '#submit' do
    context 'with invalid form' do
      it 'returns false when validation fails' do
        form.amount = nil
        expect(form.submit).to be(false)
      end

      it 'does not create transaction' do
        form.amount = 0
        expect { form.submit }.not_to change { Transaction.count }
      end
    end

    context 'for non-transfer transaction' do
      let(:account) { create(:account, user: user, name: 'Checking') }
      let(:transaction_type) { create(:transaction_type, user: user, kind: 'expense', name: 'Groceries') }
      let(:created_transaction) { create(:transaction, user: user, account: account, transaction_type: transaction_type) }

      before do
        allow(FindOrCreateAccountService).to receive(:new).with(user, 'Checking')
          .and_return(instance_double(FindOrCreateAccountService, call: account))
        allow(FindOrCreateTransactionTypeService).to receive(:new).with(user, 'Groceries', 'expense')
          .and_return(instance_double(FindOrCreateTransactionTypeService, call: transaction_type))
        allow(CreateTransactionService).to receive(:new)
          .and_return(instance_double(CreateTransactionService, call: created_transaction))
      end

      it 'calls FindOrCreateAccountService' do
        expect(FindOrCreateAccountService).to receive(:new).with(user, 'Checking').and_call_original
        form.submit
      end

      it 'calls FindOrCreateTransactionTypeService' do
        expect(FindOrCreateTransactionTypeService).to receive(:new).with(user, 'Groceries', 'expense').and_call_original
        form.submit
      end

      it 'calls CreateTransactionService with correct parameters' do
        expect(CreateTransactionService).to receive(:new).with(
          user,
          account,
          transaction_type,
          100.00,
          Date.current,
          'Weekly shopping',
          'Groceries'
        ).and_call_original
        form.submit
      end

      it 'returns true on success' do
        expect(form.submit).to be(true)
      end

      context 'when transaction is invalid' do
        let(:invalid_transaction) { build(:transaction, user: user, account: account, transaction_type: transaction_type) }
        let(:mock_errors) do
          instance_double(ActiveModel::Errors,
            messages: { amount: ['must be positive'] },
            full_messages: ['Amount must be positive']
          )
        end

        before do
          allow(invalid_transaction).to receive(:invalid?).and_return(true)
          allow(invalid_transaction).to receive(:errors).and_return(mock_errors)
          allow(CreateTransactionService).to receive(:new).and_return(instance_double(CreateTransactionService, call: invalid_transaction))
        end

        it 'returns false' do
          expect(form.submit).to be(false)
        end

        it 'promotes transaction errors to form' do
          form.submit
          expect(form.errors[:amount]).to include('must be positive')
        end

        it 'logs the error' do
          expect(Rails.logger).to receive(:error).with(/TransactionForm submit error/)
          form.submit
        end
      end
    end

    context 'for transfer transaction' do
      let(:from_account) { create(:account, user: user, name: 'Checking') }
      let(:to_account) { create(:account, user: user, name: 'Savings') }
      let(:transfer_type_out) { create(:transaction_type, user: user, kind: TransactionType::KIND_TRANSFER_OUT) }
      let(:transfer_type_in) { create(:transaction_type, user: user, kind: TransactionType::KIND_TRANSFER_IN) }
      let(:transfer_out_transaction) { create(:transaction, user: user, account: from_account, transaction_type: transfer_type_out) }
      let(:transfer_in_transaction) { create(:transaction, user: user, account: to_account, transaction_type: transfer_type_in) }

      let(:transfer_attributes) do
        {
          kind: 'transfer',
          from_account_name: 'Checking',
          to_account_name: 'Savings',
          amount: 100.00,
          transaction_date: Date.current,
          note: 'Savings transfer'
        }
      end
      let(:form) { described_class.new(user, transfer_attributes) }

      before do
        allow(FindOrCreateAccountService).to receive(:new).with(user, 'Checking')
          .and_return(instance_double(FindOrCreateAccountService, call: from_account))
        allow(FindOrCreateAccountService).to receive(:new).with(user, 'Savings')
          .and_return(instance_double(FindOrCreateAccountService, call: to_account))
        allow(FindOrCreateTransactionTypeService).to receive(:new)
          .with(user, I18n.t('transactions.transfer.type_name.transfer_out'), TransactionType::KIND_TRANSFER_OUT)
          .and_return(instance_double(FindOrCreateTransactionTypeService, call: transfer_type_out))
        allow(FindOrCreateTransactionTypeService).to receive(:new)
          .with(user, I18n.t('transactions.transfer.type_name.transfer_in'), TransactionType::KIND_TRANSFER_IN)
          .and_return(instance_double(FindOrCreateTransactionTypeService, call: transfer_type_in))

        allow(CreateTransactionService).to receive(:new).and_return(
          instance_double(CreateTransactionService, call: transfer_out_transaction),
          instance_double(CreateTransactionService, call: transfer_in_transaction)
        )
      end

      it 'creates both from_account and to_account' do
        expect(FindOrCreateAccountService).to receive(:new).with(user, 'Checking').and_call_original
        expect(FindOrCreateAccountService).to receive(:new).with(user, 'Savings').and_call_original
        form.submit
      end

      it 'creates transfer_out transaction type' do
        expect(FindOrCreateTransactionTypeService).to receive(:new)
          .with(user, I18n.t('transactions.transfer.type_name.transfer_out'), TransactionType::KIND_TRANSFER_OUT)
          .and_call_original
        form.submit
      end

      it 'creates transfer_in transaction type' do
        expect(FindOrCreateTransactionTypeService).to receive(:new)
          .with(user, I18n.t('transactions.transfer.type_name.transfer_in'), TransactionType::KIND_TRANSFER_IN)
          .and_call_original
        form.submit
      end

      it 'creates transfer_out transaction with correct parameters' do
        expected_description = I18n.t('transactions.transfer.description_out',
                                      from_account_name: 'Checking',
                                      to_account_name: 'Savings')

        expect(CreateTransactionService).to receive(:new).with(
          user,
          from_account,
          transfer_type_out,
          100.00,
          Date.current,
          'Savings transfer',
          expected_description
        ).and_call_original

        form.submit
      end

      it 'creates transfer_in transaction with correct parameters' do
        expected_description = I18n.t('transactions.transfer.description_in',
                                      from_account_name: 'Checking',
                                      to_account_name: 'Savings')

        expect(CreateTransactionService).to receive(:new).with(
          user,
          to_account,
          transfer_type_in,
          100.00,
          Date.current,
          'Savings transfer',
          expected_description
        ).and_call_original

        form.submit
      end

      it 'returns true on success' do
        expect(form.submit).to be(true)
      end

      context 'when transfer_out transaction is invalid' do
        let(:invalid_transaction) { build(:transaction, user: user, account: from_account, transaction_type: transfer_type_out) }
        let(:mock_errors) do
          instance_double(ActiveModel::Errors,
            messages: { base: ['Insufficient funds'] },
            full_messages: ['Insufficient funds']
          )
        end

        before do
          allow(invalid_transaction).to receive(:invalid?).and_return(true)
          allow(invalid_transaction).to receive(:errors).and_return(mock_errors)
          allow(CreateTransactionService).to receive(:new).and_return(instance_double(CreateTransactionService, call: invalid_transaction))
        end

        it 'returns false' do
          expect(form.submit).to be(false)
        end

        it 'promotes errors to form' do
          form.submit
          expect(form.errors[:base]).to include('Insufficient funds')
        end
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
        expect(Rails.logger).to receive(:error).with(/TransactionForm submit error: Service error/)
        form.submit
      end
    end

    context 'edge cases' do
      let(:account) { create(:account, user: user, name: 'Test Account') }
      let(:transaction_type) { create(:transaction_type, user: user, kind: 'expense') }
      let(:created_transaction) { create(:transaction, user: user, account: account, transaction_type: transaction_type) }

      before do
        allow(FindOrCreateAccountService).to receive(:new).and_return(instance_double(FindOrCreateAccountService, call: account))
        allow(FindOrCreateTransactionTypeService).to receive(:new).and_return(instance_double(FindOrCreateTransactionTypeService, call: transaction_type))
        allow(CreateTransactionService).to receive(:new).and_return(instance_double(CreateTransactionService, call: created_transaction))
      end

      it 'handles very large amounts' do
        form.amount = 999_999_999.99
        expect(form.submit).to be(true)
      end

      it 'handles decimal precision correctly' do
        form.amount = 123.456789
        expect(form.submit).to be(true)
      end

      it 'handles account names with special characters' do
        form.account_name = "John's Account (💰)"
        expect(form.submit).to be(true)
      end

      it 'handles transaction type names with special characters' do
        form.transaction_type_name = "Café & Restaurant 🍔"
        expect(form.submit).to be(true)
      end

      it 'handles very long notes' do
        form.note = 'A' * 1000
        expect(form.submit).to be(true)
      end

      it 'handles nil notes' do
        form.note = nil
        expect(form.submit).to be(true)
      end

      it 'handles dates far in the past' do
        form.transaction_date = 10.years.ago.to_date
        expect(form.submit).to be(true)
      end

      it 'handles dates far in the future' do
        form.transaction_date = 10.years.from_now.to_date
        expect(form.submit).to be(true)
      end
    end
  end

  describe 'ActiveRecord transaction rollback' do
    let(:account) { create(:account, user: user, name: 'Checking') }
    let(:transaction_type) { create(:transaction_type, user: user, kind: 'expense') }
    let(:invalid_transaction) { build(:transaction, user: user, account: account, transaction_type: transaction_type) }
    let(:mock_errors) do
      instance_double(ActiveModel::Errors,
        messages: { base: ['Error'] },
        full_messages: ['Error']
      )
    end

    before do
      allow(FindOrCreateAccountService).to receive(:new).and_return(instance_double(FindOrCreateAccountService, call: account))
      allow(FindOrCreateTransactionTypeService).to receive(:new).and_return(instance_double(FindOrCreateTransactionTypeService, call: transaction_type))
      allow(invalid_transaction).to receive(:invalid?).and_return(true)
      allow(invalid_transaction).to receive(:errors).and_return(mock_errors)
      allow(CreateTransactionService).to receive(:new).and_return(instance_double(CreateTransactionService, call: invalid_transaction))
    end

    it 'rolls back all changes when transaction creation fails' do
      expect { form.submit }.not_to change { Transaction.count }
    end

    it 'returns false on rollback' do
      expect(form.submit).to be(false)
    end
  end

  describe 'memoization' do
    let(:transfer_attributes) do
      {
        kind: 'transfer',
        from_account_name: 'Checking',
        to_account_name: 'Savings',
        amount: 100.00
      }
    end
    let(:form) { described_class.new(user, transfer_attributes) }
    let(:from_account) { create(:account, user: user, name: 'Checking') }
    let(:to_account) { create(:account, user: user, name: 'Savings') }
    let(:transfer_type_out) { create(:transaction_type, user: user, kind: TransactionType::KIND_TRANSFER_OUT) }
    let(:transfer_type_in) { create(:transaction_type, user: user, kind: TransactionType::KIND_TRANSFER_IN) }

    before do
      allow(FindOrCreateAccountService).to receive(:new).with(user, 'Checking')
        .and_return(instance_double(FindOrCreateAccountService, call: from_account))
      allow(FindOrCreateAccountService).to receive(:new).with(user, 'Savings')
        .and_return(instance_double(FindOrCreateAccountService, call: to_account))
      allow(FindOrCreateTransactionTypeService).to receive(:new)
        .with(user, I18n.t('transactions.transfer.type_name.transfer_out'), TransactionType::KIND_TRANSFER_OUT)
        .and_return(instance_double(FindOrCreateTransactionTypeService, call: transfer_type_out))
      allow(FindOrCreateTransactionTypeService).to receive(:new)
        .with(user, I18n.t('transactions.transfer.type_name.transfer_in'), TransactionType::KIND_TRANSFER_IN)
        .and_return(instance_double(FindOrCreateTransactionTypeService, call: transfer_type_in))
    end

    it 'memoizes from_account' do
      expect(FindOrCreateAccountService).to receive(:new).with(user, 'Checking').once.and_call_original
      form.send(:from_account)
      form.send(:from_account)
    end

    it 'memoizes to_account' do
      expect(FindOrCreateAccountService).to receive(:new).with(user, 'Savings').once.and_call_original
      form.send(:to_account)
      form.send(:to_account)
    end

    it 'memoizes transfer_type_out' do
      expect(FindOrCreateTransactionTypeService).to receive(:new)
        .with(user, I18n.t('transactions.transfer.type_name.transfer_out'), TransactionType::KIND_TRANSFER_OUT)
        .once.and_call_original
      form.send(:transfer_type_out)
      form.send(:transfer_type_out)
    end

    it 'memoizes transfer_type_in' do
      expect(FindOrCreateTransactionTypeService).to receive(:new)
        .with(user, I18n.t('transactions.transfer.type_name.transfer_in'), TransactionType::KIND_TRANSFER_IN)
        .once.and_call_original
      form.send(:transfer_type_in)
      form.send(:transfer_type_in)
    end
  end
end
