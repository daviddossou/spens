# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::Miner do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  # An edited attempt whose recorded kind correction is the only signal the miner reads.
  def edited_attempt(text:, kind_to:, kind_from: "expense", transaction: nil, locale: "fr")
    create(:quick_entry_attempt,
           user: user, space: space, text: text, locale: locale,
           outcome: "edited", transaction_id: transaction&.id,
           rules_draft: { "kind" => kind_from, "amount" => 5000 },
           corrections: { "kind" => { "from" => kind_from, "to" => kind_to } })
  end

  it "teaches a candidate keyword from a transfer correction" do
    edited_attempt(text: "blarg 5000 à maman", kind_to: "transfer_out")

    result = described_class.run

    learned = LearnedKeyword.find_by(phrase: "blarg")
    expect(learned).to be_present
    expect(learned).to be_candidate          # candidate-only: a human approves it in the dashboard
    expect(learned.kind).to eq("transfer")   # transfer_in/out both fold to the structural "transfer"
    expect(learned.source).to eq("miner")
    expect(result.candidates.map(&:phrase)).to eq([ "blarg" ])
  end

  it "folds a debt correction to its structural kind" do
    edited_attempt(text: "zlorp 8000", kind_to: "debt_in")

    described_class.run

    expect(LearnedKeyword.find_by(phrase: "zlorp")&.kind).to eq("debt_in")
  end

  it "excludes the resolved person from the learned phrase" do
    debt = create(:debt, space: space, name: "Koffi")
    txn = create(:transaction, space: space, debt: debt)
    edited_attempt(text: "depannage Koffi 5000", kind_to: "debt_out", transaction: txn)

    described_class.run

    expect(LearnedKeyword.pluck(:phrase)).to contain_exactly("depannage")
  end

  it "skips a correction into a non-structural kind (expense/income ride on category)" do
    attempt = edited_attempt(text: "blarg 5000", kind_to: "income")

    expect { described_class.run }.not_to change(LearnedKeyword, :count)
    expect(attempt.reload.mined_at).to be_present # still stamped so it isn't rescanned
  end

  it "ignores edited attempts with no kind correction" do
    create(:quick_entry_attempt, user: user, space: space, text: "blarg 5000",
                                 outcome: "edited",
                                 corrections: { "transaction_type_name" => { "from" => "X", "to" => "Y" } })

    expect { described_class.run }.not_to change(LearnedKeyword, :count)
  end

  it "stamps mined_at and is idempotent across reruns" do
    edited_attempt(text: "blarg 5000", kind_to: "transfer_out")

    first = described_class.run
    expect(first.scanned).to eq(1)

    second = described_class.run
    expect(second.scanned).to eq(0) # already mined → out of scope
    expect(LearnedKeyword.find_by(phrase: "blarg").confirmations).to eq(1)
  end

  it "writes nothing and stamps nothing on a dry run" do
    attempt = edited_attempt(text: "blarg 5000", kind_to: "transfer_out")

    result = described_class.run(dry_run: true)

    expect(LearnedKeyword.count).to eq(0)
    expect(attempt.reload.mined_at).to be_nil
    expect(result.candidates.map(&:phrase)).to eq([ "blarg" ]) # still previews what it would teach
  end
end
