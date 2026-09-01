# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::CorrectionLearner do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  let(:groceries_name) { TransactionTaxonomy.name("groceries", :en) }
  let(:moto_name) { TransactionTaxonomy.name("moto_taxi", :en) }

  # A transaction the user re-categorised from the parser's guess (moto_taxi) to groceries.
  def attempt_for(text:, type_name:, draft:)
    type = create(:transaction_type, space: space, name: type_name, kind: "expense")
    transaction = create(:transaction, space: space, transaction_type: type, amount: -2000)
    create(:quick_entry_attempt, user: user, space: space, transaction_id: transaction.id,
                                 text: text, source: "rules", rules_draft: draft)
    transaction
  end

  it "re-teaches a KNOWN word personally when the user overrides the built-in mapping" do
    # "carrefour" is a built-in groceries alias; the user re-categorised to street food.
    transaction = attempt_for(
      text: "5k carrefour bank",
      type_name: TransactionTaxonomy.name("street_food", :en),
      draft: { "kind" => "expense", "amount" => 5000, "transaction_type_name" => groceries_name,
               "transaction_date" => Date.current.iso8601 }
    )

    described_class.learn(transaction)

    personal = LearnedAlias.for_space(space).find_by(phrase: "carrefour")
    expect(personal).to be_active
    expect(personal.taxonomy_key).to eq("street_food")

    # And the next identical utterance resolves to the user's own category.
    draft = QuickEntry::Parser.parse("5k carrefour", space: space, locale: :en)
    expect(draft.transaction_type_name).to eq(TransactionTaxonomy.name("street_food", :en))
  end

  it "learns via template_key when the type's legacy name drifted from the taxonomy" do
    # Old template name "Transport public" ≠ today's taxonomy name "Transport en commun":
    # the name lookup finds nothing, but the template_key still identifies the node.
    type = create(:transaction_type, space: space, name: "🚌 Transport public",
                                     kind: "expense", template_key: "public_transport")
    transaction = create(:transaction, space: space, transaction_type: type, amount: -1275)
    create(:quick_entry_attempt, user: user, space: space, transaction_id: transaction.id,
                                 text: "metro ticket 12.75", source: "rules",
                                 rules_draft: { "kind" => "expense", "amount" => 1275,
                                                "transaction_type_name" => moto_name,
                                                "transaction_date" => Date.current.iso8601 })

    described_class.learn(transaction)

    personal = LearnedAlias.for_space(space).order(:created_at).last
    expect(personal).to be_present
    expect(personal.taxonomy_key).to eq("public_transport")
  end

  it "stores a token-set memory so later phrasings recall the corrected category" do
    transaction = attempt_for(
      text: "metro train ticket 500",
      type_name: TransactionTaxonomy.name("public_transport", :en),
      draft: { "kind" => "expense", "amount" => 500, "transaction_type_name" => moto_name,
               "transaction_date" => Date.current.iso8601 }
    )

    described_class.learn(transaction)

    expect(CategoryMemory.find_by(space: space)&.tokens).to include("metro", "train", "ticket")

    # A reordered subset now parses to the corrected category.
    draft = QuickEntry::Parser.parse("500 ticket metro", space: space, locale: :en)
    expect(draft.transaction_type_name).to eq(TransactionTaxonomy.name("public_transport", :en))
  end

  it "learns a global alias from a category correction" do
    transaction = attempt_for(
      text: "2000 zoomzoom",
      type_name: groceries_name,
      draft: { "kind" => "expense", "amount" => 2000, "transaction_type_name" => moto_name,
               "transaction_date" => Date.current.iso8601 }
    )

    described_class.learn(transaction)

    learned = LearnedAlias.global.find_by(phrase: "zoomzoom")
    expect(learned).to be_present
    expect(learned).to be_candidate # candidate-only: a human approves it in the dashboard
    expect(learned.taxonomy_key).to eq("groceries")

    personal = LearnedAlias.for_space(transaction.space).find_by(phrase: "zoomzoom")
    expect(personal).to be_active # the user's own correction is active for their space at once
    expect(personal.taxonomy_key).to eq("groceries")
  end

  it "records the correction and marks the attempt edited" do
    transaction = attempt_for(
      text: "2000 zoomzoom",
      type_name: groceries_name,
      draft: { "kind" => "expense", "amount" => 2000, "transaction_type_name" => moto_name,
               "transaction_date" => Date.current.iso8601 }
    )

    described_class.learn(transaction)

    attempt = QuickEntryAttempt.find_by(transaction_id: transaction.id)
    expect(attempt.outcome).to eq("edited")
    expect(attempt.corrections).to have_key("transaction_type_name")
    expect(attempt.corrections["transaction_type_name"]).to include("to" => groceries_name)
  end

  it "learns from a manual-fallback completion (blank draft category, user picked one)" do
    transaction = attempt_for(
      text: "2000 zoomzoom",
      type_name: groceries_name,
      draft: { "kind" => "expense", "amount" => 2000, "transaction_date" => Date.current.iso8601 }
    )

    described_class.learn(transaction)

    expect(LearnedAlias.find_by(phrase: "zoomzoom")&.taxonomy_key).to eq("groceries")
    attempt = QuickEntryAttempt.find_by(transaction_id: transaction.id)
    expect(attempt.outcome).to eq("edited")
    expect(attempt.corrections["transaction_type_name"]).to eq("from" => nil, "to" => groceries_name)
  end

  it "ignores a blank draft category on transfer/debt kinds (legitimately category-less)" do
    type = create(:transaction_type, space: space, name: "Transfer out", kind: "transfer_out")
    transaction = create(:transaction, space: space, transaction_type: type, amount: -2000)
    create(:quick_entry_attempt, user: user, space: space, transaction_id: transaction.id,
                                 text: "transfer 2000 to savings", source: "rules",
                                 rules_draft: { "kind" => "transfer", "amount" => 2000,
                                                "transaction_date" => Date.current.iso8601 })

    described_class.learn(transaction)

    attempt = QuickEntryAttempt.find_by(transaction_id: transaction.id)
    expect(attempt.corrections || {}).not_to have_key("transaction_type_name")
    expect(LearnedAlias.count).to eq(0)
  end

  it "does nothing when the parse matched (no diff)" do
    transaction = attempt_for(
      text: "2000 groceries",
      type_name: groceries_name,
      draft: { "kind" => "expense", "amount" => 2000, "transaction_type_name" => groceries_name,
               "transaction_date" => Date.current.iso8601 }
    )

    described_class.learn(transaction)

    expect(LearnedAlias.count).to eq(0)
    expect(QuickEntryAttempt.find_by(transaction_id: transaction.id).outcome).to eq("pending")
  end

  it "ignores transactions that didn't come from quick-entry" do
    transaction = create(:transaction, space: space)
    expect { described_class.learn(transaction) }.not_to change(LearnedAlias, :count)
  end
end
