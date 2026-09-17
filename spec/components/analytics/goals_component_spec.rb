# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::GoalsComponent, type: :component do
  before { stub_current_space(build_stubbed(:space, currency: "XOF")) }

  def progress(name: "Laptop", current: 30_000.0, target: 100_000.0, percentage: 30, rhythm_state: nil, account_id: "acc-1")
    double(goal: double(account_id: account_id), name: name, account: double(name: "Savings"),
           current: current, target: target, "target_set?": !target.nil?, percentage: percentage, rhythm_state: rhythm_state)
  end

  let(:goals) { [ progress ] }
  let(:rendered) { render_inline(described_class.new(goals: goals)) }
  let(:link) { rendered.at_css("a.analyses-goal") }

  context "without goals" do
    let(:goals) { [] }

    it "renders nothing" do
      expect(rendered.to_html.strip).to be_empty
    end
  end

  it "titles the card and links each goal by its account, at the top level" do
    expect(rendered.at_css(".analyses-card__title").text).to eq("Your goals")
    expect(link["href"]).to eq("/goals/acc-1")
    expect(link["data-turbo-frame"]).to eq("_top")
  end

  it "shows the current amount against the target in one format" do
    expect(link.at_css(".analyses-person__name").text).to eq("Laptop")
    figures = link.at_css(".analyses-goal__figures").text.squish
    expect(figures).to match(/30,000.FCFA \/ 100,000.FCFA/)
  end

  it "fills the bar to the percentage" do
    expect(link.at_css(".analyses-person__bar span")["style"]).to include("width: 30%")
  end

  it "shows no rhythm line without a rhythm state" do
    expect(link.at_css(".analyses-goal__eta")).to be_nil
  end

  context "with an ETA" do
    let(:goals) { [ progress(rhythm_state: [ :eta, Date.new(2027, 3, 1) ]) ] }

    it "names the arrival month" do
      expect(link.at_css(".analyses-goal__eta").text).to eq("At this pace: March 2027")
    end
  end

  context "without a trustworthy rhythm" do
    let(:goals) { [ progress(rhythm_state: [ :no_rhythm, nil ]) ] }

    it "says so" do
      expect(link.at_css(".analyses-goal__eta").text).to eq("No rhythm yet")
    end
  end

  context "without a target" do
    let(:goals) { [ progress(target: nil, percentage: 0) ] }

    it "shows the current amount alone" do
      figures = link.at_css(".analyses-goal__figures").text.squish
      expect(figures).to include("30,000")
      expect(figures).not_to include("/")
    end
  end

  context "when the goal has no name" do
    let(:goals) { [ progress(name: nil) ] }

    it "falls back to the account name" do
      expect(link.at_css(".analyses-person__name").text).to eq("Savings")
    end
  end

  it "renders one link per goal" do
    goals = [ progress(account_id: "a"), progress(account_id: "b"), progress(account_id: "c") ]
    rendered = render_inline(described_class.new(goals: goals))
    expect(rendered.css("a.analyses-goal").map { |a| a["href"] }).to eq([ "/goals/a", "/goals/b", "/goals/c" ])
  end
end
