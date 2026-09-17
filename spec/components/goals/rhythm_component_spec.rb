# frozen_string_literal: true

require "rails_helper"

RSpec.describe Goals::RhythmComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:account) { create(:account, space: space, balance: 200_000) }
  let(:deadline) { Date.current.beginning_of_month >> 4 }
  let(:goal) { create(:goal, space: space, account: account, target_amount: 500_000, deadline: deadline) }

  before { stub_current_space(space) }

  let(:rendered) { render_inline(described_class.new(progress: GoalProgress.new(goal))) }

  it "states the monthly amount to set aside" do
    expect(rendered.at_css(".goal-rhythm__monthly").text).to eq("60,000 FCFA a month")
  end

  it "states the target and the deadline month" do
    expect(rendered.at_css(".goal-rhythm__sub").text)
      .to eq("to reach 500,000 FCFA by #{I18n.l(deadline, format: :month_year)}")
  end

  it "hides the decorative icon from assistive tech" do
    expect(rendered.at_css(".goal-rhythm__icon")["aria-hidden"]).to eq("true")
    expect(rendered.at_css(".goal-rhythm__icon svg")).to be_present
  end

  context "with an uneven remainder" do
    let(:account) { create(:account, space: space, balance: 200_001) }

    it "rounds the monthly amount to the unit" do
      expect(rendered.at_css(".goal-rhythm__monthly").text).to eq("60,000 FCFA a month")
    end
  end
end
