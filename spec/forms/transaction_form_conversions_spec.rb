# frozen_string_literal: true

require 'rails_helper'

# Editing a transaction across kind families: income↔expense, regular↔debt, and
# to/from transfer. Each conversion keeps the opened row's id (so the Quick Entry
# correction link and the redirect stay valid) and keeps account balances /
# debt totals correct via the reverse-old / apply-new ledger.
RSpec.describe TransactionForm, 'kind conversions on edit', type: :model do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  def create_via_form(attrs)
    form = described_class.new(space, attrs)
    form.user = user
    expect(form.submit).to be(true), -> { "create failed: #{form.errors.full_messages.join(', ')}" }
    form.transaction
  end

  def edit(transaction, attrs)
    form = described_class.new(space, attrs.merge(transaction: transaction))
    form.user = user
    expect(form.submit).to be(true), -> { "edit failed: #{form.errors.full_messages.join(', ')}" }
    form.transaction
  end

  def balance(name)
    space.accounts.find_by!(name: name).balance
  end

  describe 'income → expense' do
    it 'flips the sign, the kind, and the account balance, keeping the id' do
      txn = create_via_form(kind: 'income', amount: 100, account_name: 'Cash',
                            transaction_type_name: 'Salary', transaction_date: Date.current)
      expect(balance('Cash')).to eq(100)

      result = edit(txn, kind: 'expense', transaction_type_name: 'Groceries')

      expect(result.id).to eq(txn.id)
      expect(result.transaction_type.kind).to eq('expense')
      expect(result.amount).to eq(-100)
      expect(balance('Cash')).to eq(-100)
    end
  end

  describe 'expense → debt (attach)' do
    it 'attaches a debt, grows its total, and keeps the id' do
      txn = create_via_form(kind: 'expense', amount: 50, account_name: 'Cash',
                            transaction_type_name: 'Lunch', transaction_date: Date.current)
      expect(balance('Cash')).to eq(-50)

      result = edit(txn, kind: 'debt_out', contact_name: 'Carol', direction: 'lent')

      expect(result.id).to eq(txn.id)
      expect(result.transaction_type.kind).to eq('debt_out')
      debt = space.debts.find_by(name: 'Carol', direction: 'lent')
      expect(debt).to be_present
      expect(result.debt).to eq(debt)
      expect(debt.total_lent).to eq(50)
      # Money still leaves Cash, so the balance is unchanged.
      expect(balance('Cash')).to eq(-50)
    end
  end

  describe 'debt → expense (detach)' do
    it 'detaches the debt, reverses its total, and keeps the id' do
      txn = create_via_form(kind: 'debt_out', amount: 80, account_name: 'Cash',
                            contact_name: 'Dave', direction: 'lent', transaction_date: Date.current)
      debt = space.debts.find_by!(name: 'Dave', direction: 'lent')
      expect(debt.total_lent).to eq(80)

      result = edit(txn, kind: 'expense', transaction_type_name: 'Gift')

      expect(result.id).to eq(txn.id)
      expect(result.debt).to be_nil
      expect(result.transaction_type.kind).to eq('expense')
      expect(debt.reload.total_lent).to eq(0)
      expect(balance('Cash')).to eq(-80)
    end
  end

  describe 'expense → transfer' do
    it 'creates the partner leg, pairs them, and balances both accounts' do
      txn = create_via_form(kind: 'expense', amount: 100, account_name: 'Cash',
                            transaction_type_name: 'Stuff', transaction_date: Date.current)

      result = nil
      expect do
        result = edit(txn, kind: 'transfer', from_account_name: 'Cash', to_account_name: 'Bank')
      end.to change { Transaction.count }.by(1)

      expect(result.id).to eq(txn.id)
      expect(result.transaction_type.kind).to eq('transfer_out')
      partner = result.transfer_partner
      expect(partner).to be_present
      expect(partner.transaction_type.kind).to eq('transfer_in')
      expect(result.transfer_group_id).to eq(partner.transfer_group_id)
      expect(balance('Cash')).to eq(-100)
      expect(balance('Bank')).to eq(100)
    end
  end

  describe 'transfer → expense' do
    it 'destroys the partner leg, clears the pairing, and reverses its balance' do
      out_leg = create_via_form(kind: 'transfer', amount: 100,
                               from_account_name: 'Cash', to_account_name: 'Bank',
                               transaction_date: Date.current)
      expect(balance('Cash')).to eq(-100)
      expect(balance('Bank')).to eq(100)

      result = nil
      expect do
        result = edit(out_leg, kind: 'expense', account_name: 'Cash', transaction_type_name: 'Fee')
      end.to change { Transaction.count }.by(-1)

      expect(result.id).to eq(out_leg.id)
      expect(result.transaction_type.kind).to eq('expense')
      expect(result.transfer_group_id).to be_nil
      expect(balance('Cash')).to eq(-100)
      expect(balance('Bank')).to eq(0)
    end
  end

  describe 'transfer pair edit (amount change)' do
    it 'updates both legs together' do
      out_leg = create_via_form(kind: 'transfer', amount: 100,
                               from_account_name: 'Cash', to_account_name: 'Bank',
                               transaction_date: Date.current)

      expect do
        edit(out_leg, kind: 'transfer', from_account_name: 'Cash', to_account_name: 'Bank', amount: 200)
      end.not_to change { Transaction.count }

      expect(balance('Cash')).to eq(-200)
      expect(balance('Bank')).to eq(200)
    end
  end

  describe 'editing fees' do
    def expense_with(fee: nil)
      create_via_form(kind: 'expense', amount: 100, account_name: 'Cash',
                      transaction_type_name: 'Lunch', fee_amount: fee, transaction_date: Date.current)
    end

    it 'links a fee to its parent on create' do
      txn = expense_with(fee: 5)
      expect(txn.fee).to be_present
      expect(txn.fee.fee_parent_id).to eq(txn.id)
      expect(txn.fee.amount).to eq(-5)
      expect(txn.fee.account).to eq(txn.account)
    end

    it 'adds a fee on edit when none existed' do
      txn = expense_with
      expect(txn.fee).to be_nil

      expect { edit(txn, fee_amount: 5) }.to change { Transaction.count }.by(1)

      expect(txn.reload.fee).to be_present
      expect(txn.fee.amount).to eq(-5)
    end

    it 'updates an existing fee on edit without creating a new row' do
      txn = expense_with(fee: 5)
      fee = txn.fee

      expect { edit(txn, fee_amount: 8) }.not_to change { Transaction.count }

      expect(fee.reload.amount).to eq(-8)
    end

    it 'removes the fee on edit when cleared' do
      txn = expense_with(fee: 5)

      expect { edit(txn, fee_amount: '') }.to change { Transaction.count }.by(-1)

      expect(txn.reload.fee).to be_nil
    end

    it 'prefills fee_amount on the edit form' do
      txn = expense_with(fee: 5)
      form = described_class.new(space, transaction: txn)
      expect(form.fee_amount).to eq(5)
    end
  end
end
