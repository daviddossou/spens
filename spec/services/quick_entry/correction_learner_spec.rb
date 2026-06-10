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

  it "learns a global alias from a category correction" do
    transaction = attempt_for(
      text: "2000 zoomzoom",
      type_name: groceries_name,
      draft: { "kind" => "expense", "amount" => 2000, "transaction_type_name" => moto_name,
               "transaction_date" => Date.current.iso8601 }
    )

    described_class.learn(transaction)

    learned = LearnedAlias.find_by(phrase: "zoomzoom")
    expect(learned).to be_present
    expect(learned).to be_active
    expect(learned.taxonomy_key).to eq("groceries")
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
