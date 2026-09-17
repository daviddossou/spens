# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::MovementHeroComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:account) { create(:account, space: space, name: "Wave") }
  let(:type) { create(:transaction_type, space: space, kind: "expense", name: "Groceries") }
  let(:note) { nil }
  let(:transaction) do
    create(:transaction, space: space, account: account, transaction_type: type, amount: -12_500, note: note, label: nil)
  end
  let(:row) { MovementRow.new(transaction, formatter: ->(amount) { amount.to_i.to_s }) }

  before { stub_current_space(space) }

  let(:rendered) { render_inline(described_class.new(transaction: transaction, row: row)) }

  it "shows the family icon, hidden from assistive tech" do
    icon = rendered.at_css(".movement-hero__icon")
    expect(icon["class"]).to include("transaction-item__icon--expense")
    expect(icon["aria-hidden"]).to eq("true")
    expect(icon.at_css("svg")).to be_present
  end

  it "links the signed amount to the edit form in the modal" do
    link = rendered.at_css("a.movement-hero__amount")
    expect(link["href"]).to eq("/transactions/#{transaction.id}/edit")
    expect(link["data-turbo-frame"]).to eq("modal")
    expect(link["aria-label"]).to eq("Edit")
    expect(link.text.strip).to eq("− 12,500 FCFA")
    expect(link["class"]).not_to include("movement-hero__amount--muted")
  end

  it "shows the composed subtitle and no note" do
    expect(rendered.at_css(".movement-hero__subtitle").text).to eq("Wave")
    expect(rendered.at_css(".movement-hero__note")).to be_nil
  end

  context "with a note" do
    let(:note) { "Carrefour, weekly run" }

    it "quotes the note" do
      expect(rendered.at_css(".movement-hero__note").text).to eq("« Carrefour, weekly run »")
    end
  end

  context "with an income" do
    let(:type) { create(:transaction_type, space: space, kind: "income", name: "Salary") }
    let(:transaction) { create(:transaction, space: space, account: account, transaction_type: type, amount: 300_000, label: nil) }

    it "shows a plus sign and the income family" do
      expect(rendered.at_css(".movement-hero__amount").text.strip).to eq("+ 300,000 FCFA")
      expect(rendered.at_css(".movement-hero__icon")["class"]).to include("transaction-item__icon--income")
    end
  end

  context "with a neutral line (opening balance)" do
    let(:type) { create(:transaction_type, space: space, kind: "initial_balance", name: "Opening") }
    let(:transaction) { create(:transaction, space: space, account: account, transaction_type: type, amount: 100_000, label: nil) }

    it "mutes the amount and drops the sign" do
      link = rendered.at_css("a.movement-hero__amount")
      expect(link["class"]).to include("movement-hero__amount--muted")
      expect(link.text.strip).to eq("100,000 FCFA")
      expect(rendered.at_css(".movement-hero__icon")["class"]).to include("transaction-item__icon--neutral")
      expect(rendered.at_css(".movement-hero__subtitle").text).to eq("when the account was created")
    end
  end
end
