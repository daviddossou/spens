# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionHelper, type: :helper do
  describe "#transaction_icon_class" do
    it "delegates to TransactionIconService with transaction-show scope" do
      expect(TransactionIconService).to receive(:icon_class).with("income", scope: "transaction-show")
      helper.transaction_icon_class("income")
    end
  end

  describe "#transaction_header_class" do
    it "delegates to TransactionIconService" do
      expect(TransactionIconService).to receive(:header_class).with("income")
      helper.transaction_header_class("income")
    end
  end

  describe "#transaction_amount_class" do
    it "delegates to TransactionIconService with transaction-show scope" do
      expect(TransactionIconService).to receive(:amount_class).with("expense", scope: "transaction-show")
      helper.transaction_amount_class("expense")
    end
  end

  describe "#transaction_badge_class" do
    it "delegates to TransactionIconService" do
      expect(TransactionIconService).to receive(:badge_class).with("debt_in")
      helper.transaction_badge_class("debt_in")
    end
  end

  describe "#transaction_icon_svg" do
    it "delegates to TransactionIconService" do
      expect(TransactionIconService).to receive(:icon_svg).with("transfer_in")
      helper.transaction_icon_svg("transfer_in")
    end
  end

  describe "#transaction_amount_prefix" do
    it "delegates to TransactionIconService" do
      expect(TransactionIconService).to receive(:amount_prefix).with("income")
      helper.transaction_amount_prefix("income")
    end
  end

  describe "#movement_day_total" do
    let(:space) { create(:space, currency: "EUR") }
    let(:bank) { create(:account, space: space, name: "Bank") }
    let(:wallet) { create(:account, space: space, name: "Wallet") }

    def txn(kind, amount, account)
      create(:transaction, space: space, amount: amount, account: account,
                           transaction_type: create(:transaction_type, space: space, kind: kind))
    end

    before do
      helper.define_singleton_method(:current_space) { nil }
      allow(helper).to receive(:current_space).and_return(space)
    end

    it "ignores transfers in the space scope" do
      group = SecureRandom.uuid
      out_leg = txn("transfer_out", -20_000, bank)
      in_leg = txn("transfer_in", 20_000, wallet)
      [ out_leg, in_leg ].each { |t| t.update!(transfer_group_id: group) }
      expense = txn("expense", -1_000, bank)

      html = helper.movement_day_total([ out_leg, in_leg, expense ])
      expect(html).to include(helper.money(-1_000, "EUR", sign: :always))
    end

    it "counts transfers in the account scope, where they move the balance" do
      out_leg = txn("transfer_out", -20_000, bank)
      expense = txn("expense", -1_000, bank)

      html = helper.movement_day_total([ out_leg, expense ], scope: :account)
      expect(html).to include(helper.money(-21_000, "EUR", sign: :always))
    end
  end

  describe "#transaction_top_level_options" do
    it "always offers the four top-level cards in order" do
      form = instance_double(TransactionForm, kind: "expense", debt_transaction?: false)
      expect(helper.transaction_top_level_options(form).map { |o| o[:value] }).to eq(%w[expense income transfer debt])
    end

    it "marks the matching regular card as selected" do
      form = instance_double(TransactionForm, kind: "income", debt_transaction?: false)
      opts = helper.transaction_top_level_options(form)
      expect(opts.find { |o| o[:value] == "income" }[:selected]).to be(true)
      expect(opts.find { |o| o[:value] == "debt" }[:selected]).to be(false)
    end

    it "marks the debt card selected for any debt transaction" do
      form = instance_double(TransactionForm, kind: "debt_out", debt_transaction?: true)
      opts = helper.transaction_top_level_options(form)
      expect(opts.find { |o| o[:value] == "debt" }[:selected]).to be(true)
      expect(opts.find { |o| o[:value] == "expense" }[:selected]).to be(false)
    end

    it "uses debt_out as the debt card's concrete kind target" do
      form = instance_double(TransactionForm, kind: "debt_out", debt_transaction?: true)
      expect(helper.transaction_top_level_options(form).find { |o| o[:value] == "debt" }[:kind]).to eq("debt_out")
    end
  end

  describe "#debt_direction_intent_options" do
    it "returns the lent actions, debt_in first" do
      opts = helper.debt_direction_intent_options("lent")
      expect(opts.map { |o| o[:kind] }).to eq(%w[debt_in debt_out])
      expect(opts.map { |o| o[:label] }).to eq([ "Repayment Received", "Money Lent" ])
    end

    it "returns the borrowed actions" do
      expect(helper.debt_direction_intent_options("borrowed").map { |o| o[:label] })
        .to eq([ "Money Borrowed", "Loan Repayment" ])
    end

    it "returns an empty array when the direction is blank" do
      expect(helper.debt_direction_intent_options(nil)).to eq([])
    end
  end

  describe "#debt_intent_label_map" do
    it "maps each direction to its debt_in/debt_out labels" do
      map = helper.debt_intent_label_map
      expect(map["lent"]).to eq("debt_in" => "Repayment Received", "debt_out" => "Money Lent")
      expect(map["borrowed"]).to eq("debt_in" => "Money Borrowed", "debt_out" => "Loan Repayment")
    end
  end
end
