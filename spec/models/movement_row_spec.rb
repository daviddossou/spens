# frozen_string_literal: true

require "rails_helper"

RSpec.describe MovementRow do
  let(:space) { create(:space) }
  # A deterministic formatter so subtitle amounts are easy to assert.
  let(:fmt) { ->(amount) { amount.to_i.to_s } }

  def row(transaction)
    described_class.new(transaction, currency: "XOF", locale: :en, formatter: fmt)
  end

  def type(kind, name: nil, parent: nil)
    name ||= "Category #{SecureRandom.hex(4)}"
    create(:transaction_type, space: space, kind: kind, name: name, parent: parent)
  end

  def txn(kind:, name: nil, parent: nil, amount: 1000, account: nil, debt: nil, group: nil, fee_parent: nil, label: nil)
    create(:transaction, space: space, amount: amount, label: label,
                         transaction_type: type(kind, name: name, parent: parent),
                         account: account, debt: debt, transfer_group_id: group, fee_parent_id: fee_parent)
  end

  describe "families" do
    it "maps the eight kinds onto five families" do
      expect(row(txn(kind: "income")).family).to eq(:income)
      expect(row(txn(kind: "expense")).family).to eq(:expense)
      expect(row(txn(kind: "transfer_out")).family).to eq(:transfer)
      expect(row(txn(kind: "debt_in", debt: create(:debt, space: space))).family).to eq(:debt)
      %w[debt_writeoff compensation adjustment initial_balance].each do |k|
        expect(row(txn(kind: k)).family).to eq(:neutral)
      end
    end
  end

  describe "income / expense" do
    it "titles with the category and sublines account · parent" do
      account = create(:account, space: space, name: "Bank")
      parent = type("income", name: "Revenus")
      r = row(txn(kind: "income", name: "Salaire", parent: parent, account: account))

      expect(r.title).to eq("Salaire")
      expect(r.subtitle).to eq("Bank · Revenus")
      expect(r.muted?).to be(false)
      expect(r.show_sign?).to be(true)
      expect(r.counts_in_day_total?).to be(true)
    end

    it "strips a leading emoji from the composed title" do
      r = row(txn(kind: "expense", name: "🍽️ Restaurant"))
      expect(r.title).to eq("Restaurant")
    end

    it "sublines the account alone when the category has no parent" do
      account = create(:account, space: space, name: "Wallet")
      r = row(txn(kind: "expense", name: "Groceries", account: account))
      expect(r.subtitle).to eq("Wallet")
    end

    it "uses the extracted label as the title and drops the category to the subtitle" do
      account = create(:account, space: space, name: "Bank")
      parent = type("expense", name: "Alimentation")
      r = row(txn(kind: "expense", name: "Sodas", parent: parent, account: account, label: "Coca"))

      expect(r.title).to eq("Coca")
      expect(r.subtitle).to eq("Bank · Alimentation")
    end
  end

  describe "transfers" do
    it "names the OTHER account on each leg and never counts in day totals" do
      group = SecureRandom.uuid
      bank = create(:account, space: space, name: "Bank")
      wallet = create(:account, space: space, name: "Wallet")
      out_leg = txn(kind: "transfer_out", amount: -30_000, account: bank, group: group)
      _in_leg = txn(kind: "transfer_in", amount: 30_000, account: wallet, group: group)

      r = row(out_leg)
      expect(r.title).to eq("Sent to Wallet")
      expect(r.subtitle).to eq("Bank")
      expect(r.counts_in_day_total?).to be(false)
      expect(r.muted?).to be(false)
    end
  end

  describe "debts — the four phrases" do
    let(:account) { create(:account, space: space, name: "Cash") }

    it "reads a lent debt_out as a loan" do
      debt = create(:debt, space: space, name: "Marcellin", direction: "lent", total_lent: 30_000)
      r = row(txn(kind: "debt_out", amount: -30_000, account: account, debt: debt))
      expect(r.title).to eq("Lent to Marcellin")
      expect(r.subtitle).to eq("Cash")
    end

    it "reads a borrowed debt_in as a borrow" do
      debt = create(:debt, space: space, name: "Romuald", direction: "borrowed", total_lent: 35_000)
      r = row(txn(kind: "debt_in", amount: 35_000, account: account, debt: debt))
      expect(r.title).to eq("Borrowed from Romuald")
    end

    it "reads a lent debt_in as a repayment received, with the remaining balance" do
      debt = create(:debt, space: space, name: "Sataima", direction: "lent",
                           total_lent: 50_000, total_reimbursed: 0)
      # Creating the repayment posts through the ledger: 50 000 − 5 000 = 45 000 left.
      r = row(txn(kind: "debt_in", amount: 5_000, account: account, debt: debt))
      expect(r.title).to eq("Sataima paid you back")
      expect(r.subtitle).to eq("Cash · 45000 left")
    end

    it "reads a borrowed debt_out as a repayment made, settled when nothing remains" do
      debt = create(:debt, space: space, name: "Romuald", direction: "borrowed",
                           total_lent: 35_000, total_reimbursed: 35_000)
      r = row(txn(kind: "debt_out", amount: -35_000, account: account, debt: debt))
      expect(r.title).to eq("Repaid Romuald")
      expect(r.subtitle).to eq("Cash · debt settled")
    end
  end

  describe "neutral family" do
    it "write-off is muted, unsigned, out of day totals" do
      debt = create(:debt, space: space, name: "Marcellin", direction: "lent")
      r = row(txn(kind: "debt_writeoff", amount: 30_000, debt: debt))
      expect(r.title).to eq("Write-off · Marcellin")
      expect(r.subtitle).to eq("you won't get this money back")
      expect(r.muted?).to be(true)
      expect(r.show_sign?).to be(false)
      expect(r.counts_in_day_total?).to be(false)
    end

    it "compensation reads as the mutual cancellation" do
      debt = create(:debt, space: space, name: "Romuald", direction: "lent")
      r = row(txn(kind: "compensation", amount: 35_000, debt: debt))
      expect(r.title).to eq("Compensation with Romuald")
      expect(r.subtitle).to eq("your two debts cancel out")
    end

    it "adjustment states a signed delta" do
      account = create(:account, space: space, name: "Cash")
      up = row(txn(kind: "adjustment", amount: 35_000, account: account))
      expect(up.title).to eq("Balance corrected · Cash")
      expect(up.subtitle).to eq("35000 more than expected")
      expect(up.show_sign?).to be(true)

      down = row(txn(kind: "adjustment", amount: -20_000, account: account))
      expect(down.subtitle).to eq("20000 less than expected")
    end

    it "initial balance is out of totals and unsigned" do
      account = create(:account, space: space, name: "Cash")
      r = row(txn(kind: "initial_balance", amount: 120_000, account: account))
      expect(r.title).to eq("Starting balance · Cash")
      expect(r.subtitle).to eq("when the account was created")
      expect(r.out_of_totals?).to be(true)
      expect(r.show_sign?).to be(false)
    end
  end

  describe "icon_name" do
    it "maps neutral reconciliations and write-offs to their own glyphs" do
      expect(row(txn(kind: "compensation")).icon_name).to eq("neutral")
      expect(row(txn(kind: "adjustment")).icon_name).to eq("neutral")
      expect(row(txn(kind: "initial_balance")).icon_name).to eq("neutral")
      expect(row(txn(kind: "debt_writeoff")).icon_name).to eq("writeoff")
      expect(row(txn(kind: "income")).icon_name).to eq("income")
    end
  end

  describe "fees" do
    it "flags a fee so it can be nested under its parent" do
      parent = txn(kind: "expense", amount: -2_500)
      fee = txn(kind: "expense", amount: -250, fee_parent: parent.id)
      expect(row(fee).fee?).to be(true)
      expect(row(parent).fee?).to be(false)
    end
  end
end
