# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::LearnTransactionJob, type: :job do
  let(:space) { create(:space) }
  let(:type) { create(:transaction_type, space: space, kind: "expense") }
  let(:transaction) { create(:transaction, space: space, transaction_type: type, note: "chez Diallo") }

  it "always runs the note learner" do
    expect(QuickEntry::NoteLearner).to receive(:learn).with(transaction)
    described_class.perform_now(transaction.id)
  end

  it "runs the correction learner only when asked" do
    allow(QuickEntry::NoteLearner).to receive(:learn)
    expect(QuickEntry::CorrectionLearner).to receive(:learn).with(transaction)
    described_class.perform_now(transaction.id, correction: true)
  end

  it "runs the ai-assist learner when the linked attempt used AI" do
    allow(QuickEntry::NoteLearner).to receive(:learn)
    attempt = create(:quick_entry_attempt, space: space, transaction_id: transaction.id,
                                           source: "ai", ai_used: true, ai_draft: { "phrase" => "diallo" })
    expect(QuickEntry::AiAssistLearner).to receive(:learn).with(attempt)
    described_class.perform_now(transaction.id, ai_assist: true)
  end

  it "no-ops for a missing transaction" do
    expect(QuickEntry::NoteLearner).not_to receive(:learn)
    expect { described_class.perform_now("00000000-0000-0000-0000-000000000000") }.not_to raise_error
  end
end
