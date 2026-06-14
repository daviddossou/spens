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

    it "routes an AI debt with a new person to the prefilled debt form" do
      stub_llm(kind: "debt", amount: 2000, person: "Mariam", direction: "lent")

      draft = draft_for("dépanné Mariam de 2000", locale: :fr)
      expect(draft.kind).to eq("debt_out")
      expect(draft.contact_name).to eq("Mariam")
      expect(draft.direction).to eq("lent")
      expect(draft).not_to be_confident
    end
  end
end
