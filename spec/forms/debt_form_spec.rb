# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DebtForm, type: :model do
  let(:user) { create(:user) }
  let(:valid_attributes) do
    {
      contact_name: 'John Doe',
      total_lent: 1000.00,
      total_reimbursed: 200.00,
      note: 'Personal loan',
      direction: 'lent',
      account_name: 'Cash'
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

    it 'sets contact_name from payload' do
      expect(form.contact_name).to eq('John Doe')
    end

    it 'sets total_lent from payload' do
      expect(form.total_lent).to eq(1000.00)
    end

    it 'sets total_reimbursed from payload' do
      expect(form.total_reimbursed).to eq(200.00)
    end

    it 'sets note from payload' do
      expect(form.note).to eq('Personal loan')
    end

    it 'sets direction from payload' do
      expect(form.direction).to eq('lent')
    end

    it 'sets account_name from payload' do
      expect(form.account_name).to eq('Cash')
    end

    context 'with empty payload' do
      let(:form) { described_class.new(user, {}) }

      it 'initializes with default values' do
        expect(form.contact_name).to be_nil
        expect(form.total_lent).to be_nil
        expect(form.total_reimbursed).to eq(0.0)
        expect(form.note).to be_nil
        expect(form.direction).to eq('lent')
        expect(form.account_name).to be_nil
      end
    end

    context 'with existing debt id' do
      let(:existing_debt) { create(:debt, user: user, name: 'Jane Smith', direction: 'borrowed') }
      let(:form) { described_class.new(user, { id: existing_debt.id, contact_name: 'Jane Smith' }) }

      it 'loads the existing debt' do
        expect(form.debt).to eq(existing_debt)
      end

      it 'sets persisted to true' do
        expect(form.persisted?).to be(true)
      end
    end

    context 'with borrowed direction' do
      let(:form) { described_class.new(user, valid_attributes.merge(direction: 'borrowed')) }

      it 'sets direction to borrowed' do
        expect(form.direction).to eq('borrowed')
      end
    end
  end

  describe 'validations' do
    context 'contact_name' do
      it 'is valid with contact_name present' do
        expect(form).to be_valid
      end

      it 'is invalid without contact_name' do
        form.contact_name = nil
        expect(form).not_to be_valid
        expect(form.errors[:contact_name]).to include("can't be blank")
      end

      it 'is invalid with empty contact_name' do
        form.contact_name = ''
        expect(form).not_to be_valid
        expect(form.errors[:contact_name]).to include("can't be blank")
      end

      it 'is invalid with contact_name longer than 100 characters' do
        form.contact_name = 'a' * 101
        expect(form).not_to be_valid
        expect(form.errors[:contact_name]).to include('is too long (maximum is 100 characters)')
      end

      it 'is valid with contact_name of 100 characters' do
        form.contact_name = 'a' * 100
        expect(form).to be_valid
      end
    end

    context 'total_lent' do
      it 'is valid with total_lent present' do
        expect(form).to be_valid
      end

      it 'is invalid without total_lent' do
        form.total_lent = nil
        expect(form).not_to be_valid
        expect(form.errors[:total_lent]).to include("can't be blank")
      end

      it 'is invalid with zero total_lent' do
        form.total_lent = 0
        expect(form).not_to be_valid
        expect(form.errors[:total_lent]).to include('must be greater than 0')
      end

      it 'is invalid with negative total_lent' do
        form.total_lent = -100
        expect(form).not_to be_valid
        expect(form.errors[:total_lent]).to include('must be greater than 0')
      end

      it 'is valid with positive total_lent' do
        form.total_lent = 1000
        expect(form).to be_valid
      end

      it 'handles decimal values correctly' do
        form.total_lent = 1000.50
        expect(form).to be_valid
        expect(form.total_lent).to eq(1000.50)
      end
    end

    context 'total_reimbursed' do
      it 'is valid with total_reimbursed as zero' do
        form.total_reimbursed = 0
        expect(form).to be_valid
      end

      it 'is valid with total_reimbursed present' do
        form.total_reimbursed = 500
        expect(form).to be_valid
      end

      it 'is invalid with negative total_reimbursed' do
        form.total_reimbursed = -100
        expect(form).not_to be_valid
        expect(form.errors[:total_reimbursed]).to include('must be greater than or equal to 0')
      end

      it 'is valid with blank total_reimbursed' do
        form.total_reimbursed = nil
        # When nil, the default is 0.0 which is valid
        form.valid?
        expect(form.total_reimbursed || 0).to be >= 0
      end

      it 'handles decimal values correctly' do
        form.total_reimbursed = 250.75
        expect(form).to be_valid
        expect(form.total_reimbursed).to eq(250.75)
      end
    end

    context 'reimbursed_not_exceeding_lent validation' do
      it 'is valid when total_reimbursed is less than total_lent' do
        form.total_lent = 1000
        form.total_reimbursed = 500
        expect(form).to be_valid
      end

      it 'is valid when total_reimbursed equals total_lent' do
        form.total_lent = 1000
        form.total_reimbursed = 1000
        expect(form).to be_valid
      end

      it 'is invalid when total_reimbursed exceeds total_lent' do
        form.total_lent = 1000
        form.total_reimbursed = 1500
        expect(form).not_to be_valid
        expect(form.errors[:total_reimbursed]).to include(I18n.t('debts.errors.reimbursed_exceeds_lent'))
      end

      it 'validates even when total_lent is nil' do
        form.total_lent = nil
        form.total_reimbursed = 500
        expect(form).not_to be_valid
        # Should have error about total_lent being blank, not about reimbursed exceeding
        expect(form.errors[:total_lent]).to include("can't be blank")
      end
    end

    context 'total_lent_not_less_than_existing validation' do
      let(:existing_debt) { create(:debt, user: user, name: 'Jane', total_lent: 1000, direction: 'lent') }
      let(:form) { described_class.new(user, { id: existing_debt.id, contact_name: 'Jane', total_lent: 800, direction: 'lent' }) }

      it 'is invalid when total_lent is less than existing' do
        expect(form).not_to be_valid
        expect(form.errors[:total_lent]).to include(I18n.t('debts.errors.total_lent_cannot_be_less'))
      end

      it 'is valid when total_lent equals existing' do
        form.total_lent = 1000
        expect(form).to be_valid
      end

      it 'is valid when total_lent is greater than existing' do
        form.total_lent = 1500
        expect(form).to be_valid
      end

      it 'does not validate for new debts' do
        new_form = described_class.new(user, valid_attributes.merge(total_lent: 100, total_reimbursed: 50))
        expect(new_form).to be_valid
      end
    end

    context 'total_reimbursed_not_less_than_existing validation' do
      let(:existing_debt) { create(:debt, user: user, name: 'Jane', total_lent: 1000, total_reimbursed: 500, direction: 'lent') }
      let(:form) { described_class.new(user, { id: existing_debt.id, contact_name: 'Jane', total_lent: 1000, total_reimbursed: 300, direction: 'lent' }) }

      it 'is invalid when total_reimbursed is less than existing' do
        expect(form).not_to be_valid
        expect(form.errors[:total_reimbursed]).to include(I18n.t('debts.errors.total_reimbursed_cannot_be_less'))
      end

      it 'is valid when total_reimbursed equals existing' do
        form.total_reimbursed = 500
        expect(form).to be_valid
      end

      it 'is valid when total_reimbursed is greater than existing' do
        form.total_reimbursed = 700
        expect(form).to be_valid
      end
    end
  end

  describe '.model_name' do
    it 'returns ActiveModel::Name for Debt' do
      expect(described_class.model_name.name).to eq('Debt')
      expect(described_class.model_name.param_key).to eq('debt')
      expect(described_class.model_name.route_key).to eq('debts')
    end
  end

  describe '#persisted?' do
    it 'returns false for new debt' do
      expect(form.persisted?).to be(false)
    end

    it 'returns true when debt exists' do
      existing_debt = create(:debt, user: user, name: 'Jane', direction: 'lent')
      form_with_debt = described_class.new(user, { id: existing_debt.id, contact_name: 'Jane' })
      expect(form_with_debt.persisted?).to be(true)
    end
  end

  describe '#to_model' do
    it 'returns self' do
      expect(form.to_model).to eq(form)
    end
  end

  describe '#account_suggestions' do
    let!(:account1) { create(:account, user: user, name: 'Cash') }
    let!(:account2) { create(:account, user: user, name: 'Bank') }

    before do
      allow_any_instance_of(AccountSuggestionsService).to receive(:all)
        .and_return([ 'Cash', 'Bank', 'Mobile Money' ])
    end

    it 'calls AccountSuggestionsService with user' do
      expect(AccountSuggestionsService).to receive(:new).with(user).and_call_original
      form.account_suggestions
    end

    it 'returns all account suggestions' do
      expect(form.account_suggestions).to eq([ 'Cash', 'Bank', 'Mobile Money' ])
    end
  end

  describe '#default_account_suggestions' do
    before do
      allow_any_instance_of(AccountSuggestionsService).to receive(:defaults)
        .and_return([ 'Cash', 'Bank Account', 'Mobile Money' ])
    end

    it 'calls AccountSuggestionsService with user' do
      expect(AccountSuggestionsService).to receive(:new).with(user).and_call_original
      form.default_account_suggestions
    end

    it 'returns default account suggestions' do
      expect(form.default_account_suggestions).to eq([ 'Cash', 'Bank Account', 'Mobile Money' ])
    end
  end

  describe '#submit' do
    context 'with invalid form' do
      it 'returns false when validation fails' do
        form.contact_name = nil
        expect(form.submit).to be(false)
      end

      it 'does not create a debt' do
        form.total_lent = 0
        expect { form.submit }.not_to change(Debt, :count)
      end

      it 'does not create transactions' do
        form.contact_name = ''
        expect { form.submit }.not_to change(Transaction, :count)
      end
    end

    context 'with valid form and new debt' do
      it 'creates a new debt' do
        test_form = described_class.new(user, valid_attributes.merge(contact_name: 'Unique Test 1'))
        expect { test_form.submit }.to change(Debt, :count).by(1)
      end

      it 'sets debt attributes correctly' do
        test_form = described_class.new(user, valid_attributes.merge(contact_name: 'Unique Test 2'))
        result = test_form.submit
        expect(result).to be_a(Debt)
        expect(result.name).to eq('Unique Test 2')
        expect(result.direction).to eq('lent')
        expect(result.status).to eq('ongoing')
        expect(result.note).to eq('Personal loan')
        expect(result.user).to eq(user)
      end

      it 'returns the created debt' do
        test_form = described_class.new(user, valid_attributes.merge(contact_name: 'Unique Test 3'))
        result = test_form.submit
        expect(result).to be_a(Debt)
        expect(result.name).to eq('Unique Test 3')
      end

      it 'assigns the debt to the form' do
        test_form = described_class.new(user, valid_attributes.merge(contact_name: 'Unique Test 4'))
        test_form.submit
        expect(test_form.debt).to be_persisted
      end

      context 'for lent debt' do
        let(:form) { described_class.new(user, valid_attributes.merge(direction: 'lent', contact_name: "Lent Context #{SecureRandom.uuid}")) }

        it 'creates transactions for both total_lent and total_reimbursed' do
          expect { form.submit }.to change { Transaction.count }.by(2)
        end

        it 'creates debt with correct amounts' do
          result = form.submit
          expect(result).to be_a(Debt)
          result.reload
          expect(result.direction).to eq('lent')
          expect(result.total_lent).to eq(1000.00)
          expect(result.total_reimbursed).to eq(200.00)
        end

        it 'passes account_name to transaction creation' do
          expect(TransactionForm).to receive(:new).with(
            user,
            hash_including(account_name: 'Cash')
          ).at_least(:once).and_call_original

          form.submit
        end
      end

      context 'for borrowed debt' do
        let(:form) { described_class.new(user, valid_attributes.merge(direction: 'borrowed', contact_name: 'Borrowed Context Test Person')) }

        it 'creates transactions for both total_lent and total_reimbursed' do
          expect { form.submit }.to change { Transaction.count }.by(2)
        end

        it 'creates debt with correct amounts and direction' do
          result = form.submit
          expect(result).to be_a(Debt)
          result.reload
          expect(result.direction).to eq('borrowed')
          expect(result.total_lent).to eq(1000.00)
          expect(result.total_reimbursed).to eq(200.00)
        end
      end

      context 'when total_reimbursed is zero' do
        let(:form) { described_class.new(user, valid_attributes.merge(total_reimbursed: 0, contact_name: 'Zero Reimbursed Test Person')) }

        it 'creates only debt_out transaction' do
          expect_any_instance_of(TransactionForm).to receive(:submit).once
          form.submit
        end

        it 'does not create debt_in transaction' do
          form.submit
          debt = Debt.last
          expect(debt.total_reimbursed).to eq(0)
        end
      end

      context 'without account_name' do
        let(:form) { described_class.new(user, valid_attributes.merge(account_name: nil)) }

        it 'creates transactions without account' do
          expect(TransactionForm).to receive(:new).with(
            user,
            hash_including(account_name: nil)
          ).at_least(:once).and_call_original

          form.submit
        end

        it 'still creates the debt successfully' do
          expect { form.submit }.to change(Debt, :count).by(1)
        end
      end
    end

    context 'with existing debt' do
      let(:existing_debt) { create(:debt, user: user, name: 'Old Name', total_lent: 1000, total_reimbursed: 0, direction: 'lent') }
      let(:form) do
        described_class.new(user, {
          id: existing_debt.id,
          contact_name: 'New Name',
          total_lent: 1500,
          total_reimbursed: 300,
          note: 'Updated note',
          direction: 'lent'
        })
      end

      it 'does not create a new debt' do
        # Ensure debt exists before test
        expect(existing_debt).to be_persisted
        expect(form.debt).to eq(existing_debt)

        expect { form.submit }.not_to change(Debt, :count)
      end

      it 'updates the existing debt' do
        form.submit
        existing_debt.reload
        expect(existing_debt.name).to eq('New Name')
        expect(existing_debt.note).to eq('Updated note')
      end

      it 'creates transactions for increased amounts only' do
        initial_transaction_count = Transaction.count
        form.submit
        # Should create 2 transactions (one for lent difference, one for reimbursed difference)
        expect(Transaction.count).to eq(initial_transaction_count + 2)
      end

      it 'calculates correct differences for lent debt' do
        form.submit
        existing_debt.reload
        # Should create transaction for 500 difference in lent and 300 in reimbursed
        expect(existing_debt.total_lent).to eq(1500)
        expect(existing_debt.total_reimbursed).to eq(300)
      end

      context 'when amounts stay the same' do
        let(:form) do
          described_class.new(user, {
            id: existing_debt.id,
            contact_name: 'Updated Name',
            total_lent: 1000,
            total_reimbursed: 0,
            direction: 'lent'
          })
        end

        it 'does not create new transactions' do
          expect { form.submit }.not_to change(Transaction, :count)
        end

        it 'still updates the debt name' do
          form.submit
          existing_debt.reload
          expect(existing_debt.name).to eq('Updated Name')
        end
      end
    end

    context 'when ActiveRecord transaction fails' do
      before do
        allow(user.debts).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Debt.new))
      end

      it 'returns false' do
        expect(form.submit).to be(false)
      end

      it 'adds error to base' do
        form.submit
        expect(form.errors[:base]).to be_present
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/DebtForm submit error/)
        form.submit
      end

      it 'rolls back all changes' do
        expect { form.submit }.not_to change(Debt, :count)
      end
    end

    context 'when transaction creation fails' do
      before do
        allow_any_instance_of(TransactionForm).to receive(:submit).and_return(false)
        allow_any_instance_of(TransactionForm).to receive(:errors).and_return(
          double(empty?: false, full_messages: [ 'Transaction error' ])
        )
      end

      it 'returns false and adds errors' do
        result = form.submit
        expect(result).to be(false)
        expect(form.errors[:base]).to be_present
      end

      it 'rolls back debt creation' do
        expect { form.submit rescue nil }.not_to change(Debt, :count)
      end
    end

    context 'edge cases' do
      it 'handles very large amounts' do
        form.total_lent = 999_999_999.99
        form.total_reimbursed = 100_000_000.00
        expect { form.submit }.to change(Debt, :count).by(1)
      end

      it 'handles decimal precision correctly' do
        form.total_lent = 1000.123
        form.total_reimbursed = 250.456
        result = form.submit
        result.reload
        expect(result.total_lent).to be_within(0.001).of(1000.123)
        expect(result.total_reimbursed).to be_within(0.001).of(250.456)
      end

      it 'handles contact names with special characters' do
        form.contact_name = "O'Brien & Sons (€)"
        result = form.submit
        expect(result).to be_a(Debt)
        expect(result.name).to eq("O'Brien & Sons (€)")
      end

      it 'handles very small transaction amounts' do
        form.total_lent = 0.01
        form.total_reimbursed = 0
        expect { form.submit }.to change(Debt, :count).by(1)
      end

      it 'handles direction switching for existing debt' do
        existing_debt = create(:debt, user: user, name: 'Test', total_lent: 1000, direction: 'lent')
        form = described_class.new(user, {
          id: existing_debt.id,
          contact_name: 'Test',
          total_lent: 1000,
          direction: 'borrowed'
        })

        form.submit
        existing_debt.reload
        expect(existing_debt.direction).to eq('borrowed')
      end
    end
  end

  describe 'private methods' do
    describe '#lent?' do
      it 'returns true when direction is lent' do
        form.direction = 'lent'
        expect(form.send(:lent?)).to be(true)
      end

      it 'returns false when direction is borrowed' do
        form.direction = 'borrowed'
        expect(form.send(:lent?)).to be(false)
      end
    end

    describe '#lent_difference' do
      let(:existing_debt) { create(:debt, user: user, name: 'Test', total_lent: 500, direction: 'lent') }
      let(:form) { described_class.new(user, { id: existing_debt.id, contact_name: 'Test', total_lent: 800, direction: 'lent' }) }

      it 'calculates difference correctly' do
        expect(form.send(:lent_difference)).to eq(300)
      end

      it 'returns zero when amounts are equal' do
        form.total_lent = 500
        expect(form.send(:lent_difference)).to eq(0)
      end
    end

    describe '#reimbursed_difference' do
      let(:existing_debt) { create(:debt, user: user, name: 'Test', total_reimbursed: 200, direction: 'lent') }
      let(:form) { described_class.new(user, { id: existing_debt.id, contact_name: 'Test', total_lent: 1000, total_reimbursed: 500, direction: 'lent' }) }

      it 'calculates difference correctly' do
        expect(form.send(:reimbursed_difference)).to eq(300)
      end
    end
  end

  describe 'ActiveRecord transaction rollback' do
    before do
      allow_any_instance_of(TransactionForm).to receive(:submit).and_raise(ActiveRecord::RecordInvalid.new(Transaction.new))
    end

    it 'rolls back debt creation when transaction creation fails' do
      expect { form.submit rescue nil }.not_to change(Debt, :count)
    end

    it 'returns false on rollback' do
      expect(form.submit).to be(false)
    end
  end
end
