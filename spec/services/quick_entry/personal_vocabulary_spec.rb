# frozen_string_literal: true

require "rails_helper"

# The personal (space-scoped) learning tier: active immediately, outranks the built-in
# dictionary, last correction wins, and never leaks into another space.
RSpec.describe "Personal learned vocabulary" do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  describe "precedence in the parser" do
    it "lets a personal alias override a built-in mapping" do
      # "carrefour" is a built-in groceries alias; this space decided otherwise.
      LearnedAlias.personal_teach(space: space, phrase: "carrefour", taxonomy_key: "monthly_provisions")

      draft = QuickEntry::Parser.parse("5000 carrefour", space: space, locale: :fr)

      expect(draft.transaction_type_name).to eq(TransactionTaxonomy.name("monthly_provisions", :fr))
    end

    it "resolves a phrase nobody else knows, without any admin approval" do
      LearnedAlias.personal_teach(space: space, phrase: "chez l'indien", taxonomy_key: "restaurant_maquis")

      draft = QuickEntry::Parser.parse("3000 chez l'indien", space: space, locale: :fr)

      expect(draft.transaction_type_name).to eq(TransactionTaxonomy.name("restaurant_maquis", :fr))
    end

    it "does not leak into another space" do
      other_user = create(:user)
      other_space = other_user.spaces.first
      LearnedAlias.personal_teach(space: other_space, phrase: "chez l'indien", taxonomy_key: "restaurant_maquis")

      draft = QuickEntry::Parser.parse("3000 chez l'indien", space: space, locale: :fr)

      expect(draft.transaction_type_name).to be_nil
    end

    it "uses a personal keyword for kind detection" do
      LearnedKeyword.personal_teach(space: space, phrase: "soutra", kind: "debt_out")

      draft = QuickEntry::Parser.parse("soutra Koffi 2000", space: space, locale: :fr)

      expect(draft.kind).to eq("debt_out")
    end
  end

  describe ".personal_teach" do
    it "is active immediately and stores the raw phrase for display" do
      row = LearnedAlias.personal_teach(space: space, phrase: "Chez l'Indien", taxonomy_key: "restaurant_maquis")

      expect(row).to be_active
      expect(row.source).to eq("user")
      expect(row.phrase).to eq("chezlindien")
      expect(row.display_phrase).to eq("Chez l'Indien")
    end

    it "last correction wins: a re-teach replaces the value" do
      LearnedAlias.personal_teach(space: space, phrase: "carrefour", taxonomy_key: "groceries")
      row = LearnedAlias.personal_teach(space: space, phrase: "carrefour", taxonomy_key: "monthly_provisions")

      expect(row.taxonomy_key).to eq("monthly_provisions")
      expect(row.confirmations).to eq(1)
      expect(LearnedAlias.for_space(space).where(phrase: "carrefour").count).to eq(1)
    end

    it "agreement reinforces instead of replacing" do
      LearnedAlias.personal_teach(space: space, phrase: "carrefour", taxonomy_key: "groceries")
      row = LearnedAlias.personal_teach(space: space, phrase: "carrefour", taxonomy_key: "groceries")

      expect(row.confirmations).to eq(2)
    end
  end

  describe QuickEntry::DescriptionLearner do
    it "learns the description -> category pairing from the manual form" do
      type = FindOrCreateTransactionTypeService.new(space, TransactionTaxonomy.name("restaurant_maquis", :fr), "expense").call
      transaction = create(:transaction, space: space, transaction_type: type,
                                         amount: -3000, description: "chez l'indien")

      described_class.learn(transaction, locale: :fr)

      row = LearnedAlias.for_space(space).find_by(phrase: "indien")
      expect(row).to be_active
      expect(row.taxonomy_key).to eq("restaurant_maquis")

      # An unknown word also reaches the admin queue as a global candidate.
      candidate = LearnedAlias.global.find_by(phrase: "indien")
      expect(candidate).to be_candidate
      expect(candidate.source).to eq("description")
    end

    it "no-ops when the category is a free-text custom type (no taxonomy key to map to)" do
      type = FindOrCreateTransactionTypeService.new(space, "Cotisation DD", "expense").call
      transaction = create(:transaction, space: space, transaction_type: type,
                                         amount: -3000, description: "participation famille")

      expect { described_class.learn(transaction) }.not_to change(LearnedAlias, :count)
    end
  end

  describe CategoryAliasMatcher do
    after { described_class.reload! }

    it "serves the DB system tier once imported, including admin edits" do
      described_class.reload!
      LearnedAlias.create!(phrase: "zoomzoom", display_phrase: "zoomzoom", taxonomy_key: "moto_taxi",
                           source: "system", state: "active")

      expect(described_class.match("zoomzoom")).to eq("moto_taxi")
      expect(described_class.terms("moto_taxi")).to include("zoomzoom")
    end

    it "falls back to the YML while the table has no system rows" do
      described_class.reload!

      expect(described_class.match("carrefour")).to eq("groceries")
    end
  end
end
