# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatementImports::Proposer do
  let(:user) { create(:user, first_name: "David", last_name: "Dossou") }
  let(:space) { user.spaces.first }
  let(:nsia) { create(:account, space: space, name: "NSIA") }
  let(:import) { create(:statement_import, user: user, space: space, account: nsia) }

  def line(**attrs)
    { "status" => "ok", "kind" => "expense", "currency" => "XOF" }.merge(attrs.transform_keys(&:to_s))
  end

  def propose(*captures)
    import.update!(reads: captures.each_with_index.map { |lines, i| { "capture_index" => i, "result" => { "source" => "NSIA SMS", "lines" => lines } } })
    described_class.call(import)
    import.lines.reload
  end

  it "keeps every line with its raw read and proposes only real movements" do
    lines = propose([ line(label: "SPOTIFY", amount: -2990, date: "2026-11-02 10:00"),
                      line(label: "Code OTP", amount: nil, status: "not_transaction", kind: nil) ])

    expect(lines.map(&:status)).to eq(%w[ok not_transaction])
    expect(lines.first).to have_attributes(amount: -2990, occurred_on: Date.new(2026, 11, 2), decision: "pending",
                                           account_id: nsia.id)
    expect(lines.first.extracted["label"]).to eq("SPOTIFY")
    expect(lines.last.decision).to eq("skipped")
    expect(import.reload.source).to eq("NSIA SMS")
  end

  it "reads a thousands separator taken for a decimal on a currency without cents" do
    lines = propose([ line(label: "Armandine", amount: 100.005, kind: "income") ])

    expect(lines.first.amount).to eq(100_005)
    expect(lines.first.flags).to include("thousands_separator")
  end

  it "folds a fee row into the operation that shares its number, not into one sharing a terminal id" do
    lines = propose([
      line(label: "ACHAT SUR TPE 99999999 524952548623", amount: -5721, date: "2025-09-06"),
      line(label: "ACHAT SUR TPE 99999999 525007746687", amount: -11_451, date: "2025-09-08"),
      line(label: "FRAIS SUR PMT TPE INTERNATIONAL 99999999 525007746687", amount: -1000, date: "2025-09-08")
    ])

    expect(lines.second).to have_attributes(fee: 1000, status: "ok")
    expect(lines.first.fee).to be_nil
    expect(lines.third.duplicate_of).to eq(lines.second)
    expect(lines.third.decision).to eq("skipped")
  end

  it "keeps the XOF debit of a card payment notified in USD, with the merchant's name" do
    lines = propose([
      line(label: "NETFLIX.COM", amount: -9.99, currency: "USD", date: "2026-11-06 01:52"),
      line(label: "RETRAIT DAB", amount: -5938, date: "2026-11-06 02:52")
    ])

    usd, xof = lines
    expect(usd).to have_attributes(status: "duplicate", duplicate_of: xof)
    expect(xof).to have_attributes(status: "ok", label: "NETFLIX.COM", kind: "expense")
    expect(xof.flags).not_to include("cash_withdrawal")
  end

  it "keeps two same-currency withdrawals even when the model calls one a duplicate" do
    lines = propose([
      line(label: "RETRAIT", amount: -5000, date: "2026-10-22 11:28", reference: "012A"),
      line(label: "RETRAIT", amount: -5000, date: "2026-10-22 11:28", reference: "012B", status: "duplicate")
    ])

    expect(lines.map(&:status)).to eq(%w[ok ok])
    expect(lines.last).to have_attributes(needs_review: true)
  end

  it "flags a foreign-currency line it cannot pair" do
    lines = propose([ line(label: "SPOTIFY AB", amount: -2.99, currency: "USD", date: "2025-05-14 19:58") ])

    expect(lines.first.flags).to include("foreign_currency")
  end

  it "drops the same movement seen on two captures, keeping the notice with the fee" do
    lines = propose(
      [ line(label: "Myriam", amount: -5100, date: "2026-11-22 15:51") ],
      [ line(label: "THUNES UEMOA", amount: -5000, fee: 100, reference: "13437538646", date: "2026-11-22 15:51:18") ]
    )

    app, statement = lines
    expect(app).to have_attributes(status: "duplicate", duplicate_of: statement)
    expect(statement).to have_attributes(status: "ok", fee: 100)
  end

  it "drops a repeated reference across captures" do
    lines = propose(
      [ line(label: "RETRAIT", amount: -300_000, reference: "012NPVB2631", date: "2026-10-22") ],
      [ line(label: "RETRAIT", amount: -300_000, reference: "012NPVB2631", date: "2026-10-22 08:59") ]
    )

    expect(lines.map(&:status)).to contain_exactly("ok", "duplicate")
    expect(lines.find { _1.status == "duplicate" }.flags).to include("same_reference")
  end

  it "flags a line already typed in Spens instead of proposing it twice" do
    existing = create(:transaction, space: space, account: nsia, amount: 2990, transaction_date: Date.new(2026, 11, 2))

    lines = propose([ line(label: "SPOTIFY", amount: -2990, date: "2026-11-02") ])

    expect(lines.first).to have_attributes(existing_transaction: existing, decision: "skipped")
    expect(lines.first.flags).to include("already_in_spens")
  end

  it "guesses the account from what the model saw when none was chosen" do
    import.update!(account: nil)
    nsia
    import.update!(reads: [ { "capture_index" => 0, "result" => { "account" => "NSIA Banque", "lines" => [] } } ])

    described_class.call(import)

    expect(import.reload.account).to eq(nsia)
  end
end
