# frozen_string_literal: true

require "rails_helper"

RSpec.describe Goals::CardComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:balance) { 300_000 }
  let(:target_amount) { 500_000 }
  let(:deadline) { Date.current.beginning_of_month >> 6 }
  let(:account) { create(:account, space: space, balance: balance) }
  let(:goal) do
    create(:goal, space: space, account: account, name: "Trip", target_amount: target_amount, deadline: deadline)
      .tap { |g| g.update_column(:created_at, 6.months.ago) }
  end
  let(:progress) { GoalProgress.new(goal) }

  before { stub_current_space(space) }

  let(:rendered) { render_inline(described_class.new(progress: progress)) }

  it "links the card to the goal page keyed by the account" do
    expect(rendered.at_css("a.goal-card")["href"]).to eq("/goals/#{account.id}")
    expect(rendered.at_css(".goal-card__name").text).to eq("Trip")
  end

  it "shows saved / target compactly, with a bar at the percentage" do
    expect(rendered.at_css(".goal-card__saved").text).to eq("300 k FCFA")
    expect(rendered.at_css(".goal-card__target").text).to eq(" / 500 k FCFA")
    bar = rendered.at_css(".goal-card__bar")
    expect(bar["aria-valuenow"]).to eq("60")
    expect(bar.at_css(".goal-card__bar-fill")["style"]).to eq("width: 60%;")
  end

  it "states the rhythm and an on-track chip when ahead of the calendar" do
    rhythm = rendered.at_css(".goal-card__rhythm").text
    expect(rhythm).to include("a month until #{I18n.l(deadline, format: :month_year)}")
    expect(rendered.at_css(".goal-chip--on-track").text).to eq("On track")
    expect(rendered.at_css(".goal-card__pct")).to be_nil
  end

  context "when saving lags behind the calendar" do
    let(:balance) { 50_000 }

    it "shows the behind chip" do
      expect(rendered.at_css(".goal-chip--behind").text).to eq("Behind")
    end
  end

  context "without a deadline" do
    let(:deadline) { nil }

    it "shows the free rhythm and the percentage instead of a chip" do
      expect(rendered.at_css(".goal-card__rhythm").text).to eq("At your own pace, no date")
      expect(rendered.at_css(".goal-chip")).to be_nil
      expect(rendered.at_css(".goal-card__pct").text).to eq("60%")
    end
  end

  context "when the target is reached" do
    let(:balance) { 500_000 }

    it "drops the rhythm, fills the bar and shows the reached chip" do
      expect(rendered.at_css(".goal-card__rhythm")).to be_nil
      expect(rendered.at_css(".goal-card__bar-fill--settled")["style"]).to eq("width: 100%;")
      expect(rendered.at_css(".goal-chip--reached").text).to eq("Reached")
    end
  end

  context "without a target" do
    let(:target_amount) { nil }

    it "shows only the saved amount and invites to add one" do
      expect(rendered.at_css(".goal-card__saved").text).to eq("300 k FCFA")
      expect(rendered.at_css(".goal-card__target")).to be_nil
      expect(rendered.at_css(".goal-card__bar")).to be_nil
      expect(rendered.at_css(".goal-card__meta--muted").text).to eq("No target yet — add one when you're ready")
    end
  end
end
