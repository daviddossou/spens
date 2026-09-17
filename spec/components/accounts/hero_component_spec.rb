# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::HeroComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:account) { create(:account, space: space, balance: 145_000) }
  let(:last_transaction_date) { Date.current - 3 }

  before { stub_current_space(space) }

  let(:rendered) { render_inline(described_class.new(account: account, last_transaction_date: last_transaction_date)) }

  it "shows the full balance with the space currency" do
    amount = rendered.at_css(".account-hero__amount")
    expect(amount.text).to include("145,000")
    expect(amount.text).to include("FCFA")
    expect(amount["class"]).not_to include("account-hero__amount--negative")
  end

  it "says the money is available and dates the last movement" do
    expect(rendered.at_css(".account-hero__sub").text).to include("all available · last movement 3 days ago")
  end

  context "with a movement today" do
    let(:last_transaction_date) { Date.current }

    it "says today" do
      expect(rendered.at_css(".account-hero__sub").text).to include("last movement today")
    end
  end

  context "with a movement yesterday" do
    let(:last_transaction_date) { Date.current - 1 }

    it "says yesterday" do
      expect(rendered.at_css(".account-hero__sub").text).to include("last movement yesterday")
    end
  end

  context "without any movement yet" do
    let(:last_transaction_date) { nil }

    it "drops the last-movement part" do
      expect(rendered.at_css(".account-hero__sub").text.strip).to eq("all available")
    end
  end

  context "with a negative balance" do
    let(:account) { create(:account, space: space, balance: -2_000) }

    it "marks the amount negative" do
      expect(rendered.at_css(".account-hero__amount")["class"]).to include("account-hero__amount--negative")
    end
  end

  context "with a goal on the account" do
    before { create(:goal, space: space, account: account, target_amount: 300_000) }

    it "says the money is promised to a goal instead" do
      expect(rendered.at_css(".account-hero__sub").text.strip).to eq("fully promised to a goal")
    end
  end
end
