# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatementImports::Classifier do
  let(:user) { create(:user, first_name: "David", last_name: "Dossou") }
  let(:space) { user.spaces.first }
  let(:nsia) { create(:account, space: space, name: "NSIA") }
  let(:import) { create(:statement_import, user: user, space: space, account: nsia) }

  def classify(label:, amount:, kind: "expense", reference: nil)
    draft = StatementImports::Proposer::Draft.new(label: label, reference: reference, amount: amount.to_d, kind: kind,
                                                  flags: [], needs_review: false)
    described_class.new(import).classify([ draft ])
    draft
  end

  it "makes a transfer when the text names another of the user's accounts, through a brand alias" do
    momo = create(:account, space: space, name: "💛 MoMo")

    draft = classify(label: "TRANSFERT PUSH PULL. TRANSACTION PULL MTN BENIN", amount: -250_000)

    expect(draft).to have_attributes(kind: "transfer", counterpart_account_id: momo.id)
    expect(draft.flags).to include("named_account", "transfer_out")
  end

  it "never matches on a generic word like bank or money" do
    create(:account, space: space, name: "Mobile Money")

    expect(classify(label: "MONEY TRANSFER FEE", amount: -500).kind).to eq("expense")
  end

  it "sends a cash withdrawal to the cash account" do
    cash = create(:account, space: space, name: "Espèces")

    draft = classify(label: "RETRAIT GAB 99100016", amount: -350_000)

    expect(draft).to have_attributes(kind: "transfer", counterpart_account_id: cash.id)
  end

  it "keeps a withdrawal as an expense without a cash account" do
    expect(classify(label: "RETRAIT GAB", amount: -350_000).kind).to eq("expense")
  end

  it "links a repayment to the ongoing debt named in the text" do
    debt = create(:debt, space: space, name: "Ida", direction: "lent")

    draft = classify(label: "IDA BLANDINE AFIAVI DAGBA", reference: "dettemyri", amount: 60_000, kind: "income")

    expect(draft).to have_attributes(kind: "debt_in", debt_id: debt.id)
  end

  it "flags a debt hint with no matching debt and records an income" do
    draft = classify(label: "Virginie", reference: "dette", amount: 62_000, kind: "income")

    expect(draft).to have_attributes(kind: "income", needs_review: true)
    expect(draft.flags).to include("debt_hint")
  end

  it "proposes a transfer when the holder's own name is in the text" do
    draft = classify(label: "Transfert de DOSSOU DAVID DEO-GRATIAS", amount: 500_000, kind: "income")

    expect(draft).to have_attributes(kind: "transfer", needs_review: true)
  end

  it "does not trust a transfer the text does not back" do
    draft = classify(label: "THUNES UEMOA", amount: -5000, kind: "transfer")

    expect(draft).to have_attributes(kind: "expense", needs_review: true)
    expect(draft.flags).to include("unbacked_transfer")
  end

  it "follows the sign over the model's kind" do
    expect(classify(label: "Uber Eats", amount: 15.36, kind: "expense").kind).to eq("income")
  end

  it "makes no account-based guess while the import's account is unknown" do
    import.update!(account: nil)
    create(:account, space: space, name: "MoMo")

    expect(classify(label: "PULL MTN BENIN", amount: -1000).kind).to eq("expense")
  end
end
