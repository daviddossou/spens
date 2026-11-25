# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatementImports::Categorizer do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:import) { create(:statement_import, user: user, space: space, status: "ready") }

  def line(label, kind: "expense", amount: -2000)
    import.lines.create!(position: import.lines.count + 1, capture_index: 0, status: "ok", kind: kind, amount: amount, label: label)
  end

  it "uses the quick-add rules and trusts what they find" do
    l = line("Carrefour Market")

    described_class.call(import)

    expect(l.reload.transaction_type_name).to be_present
    expect(l.category_source).to eq("rules")
    expect(l.categorization).to include("text" => "2000 Carrefour Market", "proposed" => l.transaction_type_name)
  end

  it "asks the same AI fallback as quick add when the rules find nothing, and marks it uncertain" do
    allow(QuickEntry::Coordinator).to receive(:ai_enabled?).and_return(true)
    allow(QuickEntry::Coordinator).to receive(:call).and_call_original
    ai = QuickEntry::Coordinator::Result.new(
      draft: QuickEntry::Draft.new(kind: "expense", amount: 2000, transaction_type_name: "🧺 Groceries"),
      ai_draft: { "category_key" => "groceries", "phrase" => "koro" }
    )
    allow(QuickEntry::Coordinator).to receive(:call).with(anything, hash_including(ai: true)).and_return(ai)
    l = line("KoRo")

    described_class.call(import)

    expect(l.reload).to have_attributes(transaction_type_name: "🧺 Groceries", category_source: "ai")
    expect(l.review_reason).to eq("uncertain_category")
  end

  it "never gives an expense category to money in" do
    allow(QuickEntry::Coordinator).to receive(:ai_enabled?).and_return(false)
    expense = QuickEntry::Coordinator::Result.new(draft: QuickEntry::Draft.new(kind: "expense", amount: 2000, transaction_type_name: "🛒 Groceries"), ai_draft: nil)
    allow(QuickEntry::Coordinator).to receive(:call).and_return(expense)
    l = line("Carrefour Market", kind: "income", amount: 2000)

    described_class.call(import)

    expect(l.reload).to have_attributes(transaction_type_name: TransactionTaxonomy.name("other_income", :en), category_source: "fallback")
    expect(QuickEntry::Coordinator).to have_received(:call).with(start_with("received 2000"), anything)
  end

  it "files a line nothing matched under Other, still ticked but among the lines to check" do
    allow(QuickEntry::Coordinator).to receive(:ai_enabled?).and_return(false)
    l = line("ZZQX 4471")

    described_class.call(import)

    expect(l.reload).to have_attributes(transaction_type_name: TransactionTaxonomy.name("other_expense", :en), category_source: "fallback")
    expect(l.review_reason).to eq("fallback_category")
    expect(l.categorization["proposed"]).to be_nil
  end

  it "leaves transfers alone" do
    l = line("RETRAIT GAB", kind: "transfer")

    described_class.call(import)

    expect(l.reload.transaction_type_name).to be_nil
  end
end
