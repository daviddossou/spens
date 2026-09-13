# frozen_string_literal: true

require "rails_helper"

RSpec.describe DestroyTransactionService do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  it "marks the quick-entry attempt deleted before the transaction goes" do
    transaction = create(:transaction, space: space)
    attempt = create(:quick_entry_attempt, user: user, space: space, transaction_id: transaction.id)
    allow(Analytics).to receive(:track_quick_entry_resolved)

    described_class.new(transaction).call

    expect(attempt.reload.outcome).to eq("deleted")
    expect(Transaction.exists?(transaction.id)).to be(false)
    expect(Analytics).to have_received(:track_quick_entry_resolved).with(attempt)
  end
end
