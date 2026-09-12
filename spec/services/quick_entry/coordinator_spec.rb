# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::Coordinator do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  def draft_for(text, locale: :en) = described_class.call(text, space: space, locale: locale).draft

  it "returns a confident rules draft" do
    draft = draft_for("2000 zem")
    expect(draft).to be_confident
    expect(draft.transaction_type_name).to eq(TransactionTaxonomy.name("moto_taxi", :en))
  end

  it "keeps the raw text as the note on a rules-only draft" do
    create(:account, space: space, name: "Compte bancaire")

    draft = draft_for("essence JNP 5000 compte bancaire", locale: :fr)

    expect(draft).to be_confident
    expect(draft.note).to eq("essence JNP 5000 compte bancaire")
  end

  it "parses a French utterance even in an English session (language auto-detection)" do
    create(:account, space: space, name: "Orabank")
    create(:account, space: space, name: "Mobile money")

    draft = draft_for("J'ai transféré 300k de mon Orabank à mon Mobile money", locale: :en)

    expect(draft.kind).to eq("transfer")
    expect(draft.from_account_name).to eq("Orabank")
    expect(draft.to_account_name).to eq("Mobile money")
    expect(draft).to be_confident
  end

  it "links a repayment to a known debt named in the utterance" do
    debt = create(:debt, user: user, name: "Julius", direction: "lent")

    draft = draft_for("received 25000 from Julius")

    expect(draft.kind).to eq("debt_in")
    expect(draft.debt_id).to eq(debt.id)
  end

  context "with the LLM enabled" do
    before { allow(QuickEntry::LlmParser).to receive(:enabled?).and_return(true) }

    it "lets the AI settle an ambiguous amount when it picks one of the candidates" do
      stub_llm(kind: "expense", amount: 10, category_key: "groceries", category_name: TransactionTaxonomy.name("groceries", :en))
      draft = draft_for("25 balls of attieke 10 each")
      expect(draft.amount).to eq(10)
      expect(draft.unresolved).not_to include(:amount)
    end

    it "keeps the amount unresolved when the AI computes a total that isn't in the phrase" do
      stub_llm(kind: "expense", amount: 250, category_key: "groceries", category_name: TransactionTaxonomy.name("groceries", :en))
      draft = draft_for("25 balls of attieke 10 each")
      expect(draft.amount).to eq(25)
      expect(draft.amount_candidates).to eq([ 25, 10 ])
      expect(draft.unresolved).to include(:amount)
      expect(draft).not_to be_confident
    end

    it "ignores an AI transfer that names no two existing accounts (a mentioned account is not a transfer)" do
      create(:account, space: space, name: "MTN Momo")
      stub_llm(kind: "transfer", amount: 1000, to_account: "MTN Momo")

      draft = draft_for("attieke 1000 on my MTN Momo")
      expect(draft.kind).to eq("expense")
      expect(draft.account_name).to eq("MTN Momo")
    end

    it "ignores an AI debt that names no person" do
      stub_llm(kind: "debt", amount: 25, direction: "lent")

      draft = draft_for("attieke 25 balls")
      expect(draft.kind).to eq("expense")
      expect(draft.amount).to eq(25)
    end

    it "ignores an AI transfer whose two ends are both unknown accounts" do
      stub_llm(kind: "transfer", amount: 1000, from_account: "Attieke", to_account: "Balls")

      expect(draft_for("attieke 1000 balls").kind).to eq("expense")
    end

    it "derives the kind from the AI's category, never from a contradicting stated kind" do
      stub_llm(kind: "income", amount: 3000, category_key: "groceries", category_name: TransactionTaxonomy.name("groceries", :en))
      expect(draft_for("3000 ndogou").kind).to eq("expense")
    end

    def stub_llm(**attrs)
      llm = instance_double(QuickEntry::LlmParser, parse: QuickEntry::LlmParser::Result.new(**attrs))
      allow(QuickEntry::LlmParser).to receive(:new).and_return(llm)
    end

    it "does not consult the LLM when the rules are already confident" do
      expect(QuickEntry::LlmParser).not_to receive(:new)
      draft_for("2000 zem")
    end

    it "auto-creates a known-person debt only when the direction is clear, without the LLM" do
      create(:debt, user: user, name: "Julius", direction: "lent")
      expect(QuickEntry::LlmParser).not_to receive(:new)

      draft = draft_for("received 2000 from Julius")
      expect(draft.kind).to eq("debt_in")
      expect(draft.debt_id).to be_present
    end

    it "opens the debt form (no LLM) for a bare person mention with no direction" do
      create(:debt, user: user, name: "Julius", direction: "lent")
      expect(QuickEntry::LlmParser).not_to receive(:new)

      draft = draft_for("2000 Julius")
      expect(draft.contact_name).to eq("Julius")
      expect(draft).not_to be_confident
    end

    it "fills a category gap from the LLM and surfaces its raw output" do
      stub_llm(kind: "expense", amount: 3000, category_key: "groceries",
               category_name: TransactionTaxonomy.name("groceries", :en), phrase: "ndogou")

      result = described_class.call("3000 ndogou", space: space, locale: :en)

      expect(result.draft).to be_confident
      expect(result.draft.transaction_type_name).to eq(TransactionTaxonomy.name("groceries", :en))
      expect(result.ai_draft["phrase"]).to eq("ndogou")
    end

    it "auto-creates a transfer when the AI's two accounts both exist" do
      create(:account, space: space, name: "Orabank")
      create(:account, space: space, name: "Wave")
      stub_llm(kind: "transfer", amount: 50_000, from_account: "Orabank", to_account: "Wave")

      draft = draft_for("balance 50k vers Wave")
      expect(draft.kind).to eq("transfer")
      expect(draft.from_account_name).to eq("Orabank")
      expect(draft.to_account_name).to eq("Wave")
      expect(draft).to be_confident
    end

    it "routes an AI transfer with a new account to the prefilled form (not confident)" do
      create(:account, space: space, name: "Wave")
      stub_llm(kind: "transfer", amount: 50_000, from_account: "Ecobank", to_account: "Wave")

      draft = draft_for("envoyé 50k vers Wave")
      expect(draft.kind).to eq("transfer")
      expect(draft.to_account_name).to eq("Wave")
      expect(draft.from_account_name).to be_nil
      expect(draft).not_to be_confident
    end

    it "auto-creates a debt with a new person from the AI's person + direction" do
      stub_llm(kind: "debt", amount: 2000, person: "Mariam", direction: "lent")

      draft = draft_for("dépanné Mariam de 2000", locale: :fr)
      expect(draft.kind).to eq("debt_out")
      expect(draft.contact_name).to eq("Mariam")
      expect(draft.direction).to eq("lent")
      expect(draft).to be_confident
    end

    it "reads an AI debt without a named person as a plain expense (the user can still pick Debt)" do
      stub_llm(kind: "debt", amount: 2000, person: nil, direction: "lent")

      draft = draft_for("dépanné quelqu'un de 2000", locale: :fr)
      expect(draft.kind).to eq("expense")
      expect(draft.amount).to eq(2000)
    end
  end
end
