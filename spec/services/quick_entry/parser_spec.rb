# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::Parser do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  def parse(text, locale: :en) = described_class.parse(text, space: space, locale: locale)

  describe "amount" do
    it "reads plain digits and thousands separators" do
      expect(parse("2000 zem").amount).to eq(2000)
      expect(parse("2 000 zem").amount).to eq(2000)
    end

    it "reads k/m shorthands" do
      expect(parse("5k groceries").amount).to eq(5000)
      expect(parse("2.5k groceries").amount).to eq(2500)
    end

    it "reads spelled-out numbers (EN and FR)" do
      expect(parse("two thousand").amount).to eq(2000)
      expect(parse("deux mille cinq cents", locale: :fr).amount).to eq(2500)
    end
  end

  describe "category + kind" do
    it "infers an expense category from a merchant/mode" do
      draft = parse("2000 zem")
      expect(draft.kind).to eq("expense")
      expect(draft.transaction_type_name).to eq(TransactionTaxonomy.name("moto_taxi", :en))
      expect(draft).to be_confident
    end

    it "infers income from an income word + category (FR)" do
      draft = parse("reçu 50000 salaire", locale: :fr)
      expect(draft.kind).to eq("income")
      expect(draft.amount).to eq(50_000)
      expect(draft.transaction_type_name).to eq(TransactionTaxonomy.name("salary", :fr))
      expect(draft).to be_confident
    end

    it "lets the category settle the kind when no kind word fired" do
      # "rent" is an expense category; no kind keyword, so it stays expense
      expect(parse("25000 rent").kind).to eq("expense")
    end

    it "reads an unknown verb as expense until a learned keyword is approved" do
      expect(parse("j'ai dépanné Ali de 2000", locale: :fr).kind).to eq("expense")

      LearnedKeyword.teach(phrase: "dépanné", kind: "debt_out", source: "ai").approve!

      expect(parse("j'ai dépanné Ali de 2000", locale: :fr).kind).to eq("debt_out")
    end

    it "consults a learned keyword only as a gap-fill, never over a built-in" do
      LearnedKeyword.teach(phrase: "depanne", kind: "debt_out", source: "ai")&.approve!
      # a built-in income word still wins outright
      expect(parse("reçu 50000 salaire", locale: :fr).kind).to eq("income")
    end
  end

  describe "date" do
    it "defaults to today and reads yesterday/hier" do
      expect(parse("2000 zem").transaction_date).to eq(Date.current)
      expect(parse("5k groceries yesterday").transaction_date).to eq(Date.current - 1)
      expect(parse("2000 zem hier", locale: :fr).transaction_date).to eq(Date.current - 1)
    end

    it "reads day-before-yesterday and N days/weeks ago" do
      expect(parse("2000 zem day before yesterday").transaction_date).to eq(Date.current - 2)
      expect(parse("2000 zem avant-hier", locale: :fr).transaction_date).to eq(Date.current - 2)
      expect(parse("5k groceries 3 days ago").transaction_date).to eq(Date.current - 3)
      expect(parse("5k groceries 2 weeks ago").transaction_date).to eq(Date.current - 14)
    end

    it "reads a named weekday as its most recent past occurrence" do
      monday = Date.current - ((Date.current.cwday - 1) % 7)
      expect(parse("2000 zem on monday").transaction_date).to eq(monday)
    end
  end

  describe "account" do
    it "matches an existing account name" do
      create(:account, space: space, name: "MTN MoMo")
      expect(parse("2000 zem from MTN MoMo").account_name).to eq("MTN MoMo")
    end

    it "is blank when no account is mentioned" do
      expect(parse("2000 zem").account_name).to be_nil
    end
  end

  describe "transfer" do
    it "extracts both ends + a spelled-out fee and is confident when both accounts exist (FR)" do
      create(:account, space: space, name: "Orabank")
      create(:account, space: space, name: "Mobile money")

      draft = parse(
        "J'ai transféré 300k de mon Orabank à mon Mobile money et ça m'a pris sept cent comme frais",
        locale: :fr
      )

      expect(draft.kind).to eq("transfer")
      expect(draft.amount).to eq(300_000)
      expect(draft.from_account_name).to eq("Orabank")
      expect(draft.to_account_name).to eq("Mobile money")
      expect(draft.fee_amount).to eq(700)
      expect(draft).to be_confident
    end

    it "prefills what it can but stays unconfident when an account is unknown (EN)" do
      create(:account, space: space, name: "Mobile money")

      draft = parse("transferred 50000 from Ecobank to Mobile money with 500 fee")

      expect(draft.amount).to eq(50_000)
      expect(draft.from_account_name).to be_nil
      expect(draft.to_account_name).to eq("Mobile money")
      expect(draft.fee_amount).to eq(500)
      expect(draft).not_to be_confident
      expect(draft.unresolved).to include(:from_account)
    end

    it "does not mistake the main amount for a fee" do
      create(:account, space: space, name: "Cash")
      create(:account, space: space, name: "Wave")

      draft = parse("transfer 10000 from Cash to Wave")
      expect(draft.fee_amount).to be_nil
    end
  end

  describe "confidence / fallback" do
    it "is not confident without an amount" do
      draft = parse("groceries")
      expect(draft.amount).to be_nil
      expect(draft).not_to be_confident
      expect(draft.unresolved).to include(:amount)
    end

    it "is not confident without a category" do
      draft = parse("5k")
      expect(draft).not_to be_confident
      expect(draft.unresolved).to include(:category)
    end

    it "routes a transfer with unknown accounts to the manual form (not auto-create)" do
      expect(parse("transfer 10000 to savings")).not_to be_confident
      expect(parse("lent 5000 to John")).not_to be_confident
    end
  end
end
