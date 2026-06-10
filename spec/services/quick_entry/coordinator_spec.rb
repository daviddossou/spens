# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::Coordinator do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  it "returns a confident rules draft" do
    draft = described_class.call("2000 zem", space: space, locale: :en)
    expect(draft).to be_confident
    expect(draft.transaction_type_name).to eq(TransactionTaxonomy.name("moto_taxi", :en))
  end

  it "parses a French utterance even in an English session (language auto-detection)" do
    create(:account, space: space, name: "Orabank")
    create(:account, space: space, name: "Mobile money")

    draft = described_class.call(
      "J'ai transféré 300k de mon Orabank à mon Mobile money", space: space, locale: :en
    )

    expect(draft.kind).to eq("transfer")
    expect(draft.from_account_name).to eq("Orabank")
    expect(draft.to_account_name).to eq("Mobile money")
    expect(draft).to be_confident
  end

  it "links a repayment to a known debt named in the utterance" do
    debt = create(:debt, user: user, name: "Julius", direction: "lent")

    draft = described_class.call("received 25000 from Julius", space: space, locale: :en)

    expect(draft.kind).to eq("debt_in")
    expect(draft.debt_id).to eq(debt.id)
  end
end
