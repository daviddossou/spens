# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransactionLedger do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:account) { create(:account, space: space, balance: 0.0) }

  # Build a transaction WITHOUT the factory's after(:create) ledger hook so we
  # can exercise apply/reverse explicitly here.
  def unposted_transaction(type_kind:, amount:, debt: nil)
    type = create(:transaction_type, space: space, kind: type_kind)
    build(:transaction, space: space, account: account, transaction_type: type, amount: amount, debt: debt)
      .tap { |t| t.save!(validate: false) }
  end

  describe 'account balance' do
    it 'apply adds the signed amount; reverse undoes it' do
      txn = unposted_transaction(type_kind: 'expense', amount: -40)

      TransactionLedger.apply(TransactionLedger.snapshot(txn))
      expect(account.reload.balance).to eq(-40)

      TransactionLedger.reverse(TransactionLedger.snapshot(txn))
      expect(account.reload.balance).to eq(0)
    end
  end

  describe 'debt totals' do
    it 'grows total_lent when lending more on a lent debt' do
      debt = create(:debt, space: space, direction: 'lent', total_lent: 0, total_reimbursed: 0)
      txn = unposted_transaction(type_kind: 'debt_out', amount: -30, debt: debt)

      TransactionLedger.apply(TransactionLedger.snapshot(txn))
      expect(debt.reload.total_lent).to eq(30)
      expect(debt.total_reimbursed).to eq(0)
    end

    it 'grows total_reimbursed when repaying a lent debt' do
      debt = create(:debt, space: space, direction: 'lent', total_lent: 100, total_reimbursed: 0)
      txn = unposted_transaction(type_kind: 'debt_in', amount: 25, debt: debt)

      TransactionLedger.apply(TransactionLedger.snapshot(txn))
      expect(debt.reload.total_reimbursed).to eq(25)
      expect(debt.total_lent).to eq(100)
    end
  end

  it 'no-ops when there is no account or debt' do
    type = create(:transaction_type, space: space, kind: 'expense')
    txn = build(:transaction, space: space, account: nil, transaction_type: type, amount: -10, debt: nil)
             .tap { |t| t.save!(validate: false) }

    expect { TransactionLedger.apply(TransactionLedger.snapshot(txn)) }.not_to raise_error
  end
end
