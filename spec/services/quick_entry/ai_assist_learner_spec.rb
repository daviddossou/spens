# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::AiAssistLearner do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  it "stores the AI's phrase -> key as a candidate alias (not yet trusted)" do
    attempt = create(:quick_entry_attempt, user: user, space: space, ai_used: true,
                                           ai_draft: { "phrase" => "ndogou", "category_key" => "groceries" })

    described_class.learn(attempt)

    learned = LearnedAlias.find_by(phrase: "ndogou")
    expect(learned).to be_present
    expect(learned).to be_candidate
    expect(learned.taxonomy_key).to eq("groceries")
  end

  it "no-ops without an AI phrase/key" do
    attempt = create(:quick_entry_attempt, user: user, space: space)
    expect { described_class.learn(attempt) }.not_to change(LearnedAlias, :count)
  end

  it "captures the verb of a debt the rules missed as a candidate kind keyword" do
    attempt = create(:quick_entry_attempt, user: user, space: space, ai_used: true,
                                           text: "j'ai dépanné Ali de 2k", locale: "fr",
                                           ai_draft: { "kind" => "debt", "direction" => "lent", "person" => "Ali" })

    described_class.learn(attempt)

    learned = LearnedKeyword.find_by(phrase: "depanne")
    expect(learned).to be_candidate
    expect(learned.kind).to eq("debt_out")
  end

  it "captures a novel transfer verb, excluding the accounts the AI named" do
    attempt = create(:quick_entry_attempt, user: user, space: space, ai_used: true,
                                           text: "j'ai basculé 50k de Orabank vers Ecobank", locale: "fr",
                                           ai_draft: { "kind" => "transfer", "from_account" => "Orabank",
                                                       "to_account" => "Ecobank" })

    described_class.learn(attempt)

    expect(LearnedKeyword.find_by(phrase: "bascule")&.kind).to eq("transfer")
    expect(LearnedKeyword.where(phrase: %w[orabank ecobank])).to be_empty
  end

  it "learns no kind keyword for a plain expense the AI categorised" do
    attempt = create(:quick_entry_attempt, user: user, space: space, ai_used: true,
                                           text: "1500 garba", locale: "fr",
                                           ai_draft: { "kind" => "expense", "phrase" => "garba",
                                                       "category_key" => "groceries" })

    expect { described_class.learn(attempt) }.not_to change(LearnedKeyword, :count)
  end
end
