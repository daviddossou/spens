# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::GoalSummaryComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:account) { create(:account, space: space, name: "Savings", balance: 200_000) }
  let(:deadline) { Date.current.beginning_of_month >> 4 }
  let!(:goal) { create(:goal, space: space, account: account, name: "New laptop", target_amount: 500_000, deadline: deadline) }
  let(:progress) { GoalProgress.new(goal) }

  before { stub_current_space(space) }

  let(:rendered) { render_inline(described_class.new(account: account.reload, progress: progress)) }

  it "names the goal and links to its page through the account id" do
    expect(rendered.at_css(".account-goal-card__name").text).to eq("New laptop")
    link = rendered.at_css("a.account-goal-card__link")
    expect(link.text).to eq("View")
    expect(link["href"]).to eq("/goals/#{account.id}")
  end

  it "shows saved of target in full amounts" do
    amount = rendered.at_css(".account-goal-card__amount").text
    expect(amount).to include("200,000")
    expect(rendered.at_css(".account-goal-card__target").text).to include("of 500,000")
  end

  it "renders the progress bar at the goal percentage" do
    bar = rendered.at_css(".account-goal-card__bar")
    expect(bar["role"]).to eq("progressbar")
    expect(bar["aria-valuenow"]).to eq("40")
    expect(bar.at_css(".account-goal-card__bar-fill")["style"]).to eq("width: 40%;")
    expect(bar.at_css(".account-goal-card__bar-fill--settled")).to be_nil
  end

  it "states the monthly pace up to the deadline" do
    meta = rendered.at_css(".account-goal-card__meta").text
    expect(meta).to include("Due #{I18n.l(deadline, format: :month_year)}")
    expect(meta).to include("60,000 FCFA a month".sub(" FCFA", " FCFA"))
  end

  context "without a deadline" do
    let(:deadline) { nil }

    it "says the goal has no date" do
      expect(rendered.at_css(".account-goal-card__meta").text.strip).to eq("At your own pace, no date")
    end
  end

  context "when the goal is reached" do
    let(:account) { create(:account, space: space, name: "Savings", balance: 500_000) }

    it "fills the bar with the settled style" do
      expect(rendered.at_css(".account-goal-card__bar-fill--settled")["style"]).to eq("width: 100%;")
    end
  end
end
