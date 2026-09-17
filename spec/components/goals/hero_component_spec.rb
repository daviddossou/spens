# frozen_string_literal: true

require "rails_helper"

RSpec.describe Goals::HeroComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:balance) { 300_000 }
  let(:account) { create(:account, space: space, balance: balance) }
  let(:deadline) { Date.current.beginning_of_month >> 3 }
  let(:goal) do
    create(:goal, space: space, account: account, target_amount: 500_000, deadline: deadline)
      .tap { |g| g.update_column(:created_at, 1.month.ago) }
  end
  let(:progress) { GoalProgress.new(goal) }

  before { stub_current_space(space) }

  let(:rendered) { render_inline(described_class.new(account: account, progress: progress)) }

  it "shows the saved amount, the target and the bar" do
    expect(rendered.at_css(".goal-hero__amount").text).to eq("300,000 FCFA")
    expect(rendered.at_css(".goal-hero__target").text).to eq("of 500,000 FCFA")
    bar = rendered.at_css(".goal-hero__bar")
    expect(bar["aria-valuenow"]).to eq("60")
    expect(bar.at_css(".goal-hero__bar-fill")["style"]).to eq("width: 60%;")
    expect(rendered.at_css(".goal-hero__label")).to be_nil
  end

  it "summarises what is left, the months and the status" do
    meta = rendered.at_css(".goal-hero__meta")
    expect(meta.text).to include("200,000 FCFA to go")
    expect(meta.text).to include("4 months")
    expect(meta.at_css(".goal-chip--on-track").text).to eq("On track")
  end

  context "when the target is reached" do
    let(:balance) { 500_000 }

    it "shows only the reached chip with a settled bar" do
      expect(rendered.at_css(".goal-hero__bar-fill--settled")).to be_present
      expect(rendered.at_css(".goal-hero__meta").text.strip).to eq("Reached")
    end
  end

  context "without a deadline" do
    let(:deadline) { nil }

    it "shows the remaining amount and the percentage" do
      expect(rendered.at_css(".goal-hero__meta").text).to eq("200,000 FCFA to go · 60%")
    end
  end

  context "without a target" do
    let(:goal) { create(:goal, space: space, account: account, target_amount: nil) }

    it "falls back to the saved label" do
      expect(rendered.at_css(".goal-hero__amount").text).to eq("300,000 FCFA")
      expect(rendered.at_css(".goal-hero__label").text).to eq("saved")
      expect(rendered.at_css(".goal-hero__bar")).to be_nil
    end
  end

  context "without any progress" do
    let(:progress) { nil }

    it "shows the account balance as saved" do
      expect(rendered.at_css(".goal-hero__amount").text).to eq("300,000 FCFA")
      expect(rendered.at_css(".goal-hero__label").text).to eq("saved")
    end
  end
end
