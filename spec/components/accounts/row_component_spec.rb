# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::RowComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:account) { create(:account, space: space, name: "Wave", balance: 145_000) }

  before { stub_current_space(space) }

  let(:rendered) { render_inline(described_class.new(account: account.reload)) }

  it "links the whole row to the account" do
    link = rendered.at_css("a.account-row")
    expect(link["href"]).to eq("/accounts/#{account.id}")
    expect(link.at_css(".account-row__chevron")).to be_present
  end

  it "shows the name and the full balance" do
    expect(rendered.at_css(".account-row__name").text).to eq("Wave")
    balance = rendered.at_css(".account-row__balance")
    expect(balance.text).to eq("145,000 FCFA")
    expect(balance["class"]).not_to include("account-row__balance--negative")
  end

  it "has no goal line without a goal" do
    expect(rendered.at_css(".account-row__goal")).to be_nil
  end

  context "with a negative balance" do
    let(:account) { create(:account, space: space, balance: -500) }

    it "marks the balance negative" do
      expect(rendered.at_css(".account-row__balance")["class"]).to include("account-row__balance--negative")
    end
  end

  context "with a goal and a target" do
    before { create(:goal, space: space, account: account, name: "Trip", target_amount: 580_000) }

    it "states the promise with a slim bar" do
      bar = rendered.at_css(".account-row__bar")
      expect(bar["aria-valuenow"]).to eq("25")
      expect(bar.at_css(".account-row__bar-fill")["style"]).to eq("width: 25%;")
      expect(rendered.at_css(".account-row__goal-text").text).to eq("Trip · 25 % of 580,000 FCFA")
    end
  end

  context "with a goal but no target" do
    before { create(:goal, space: space, account: account, name: "Trip", target_amount: nil) }

    it "shows no goal line" do
      expect(rendered.at_css(".account-row__goal")).to be_nil
    end
  end
end
