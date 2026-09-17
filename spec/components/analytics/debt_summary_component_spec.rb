# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::DebtSummaryComponent, type: :component do
  before { stub_current_space(build_stubbed(:space, currency: "XOF")) }

  def relation(name, direction, amount, debt_id)
    double(name: name, initials: name.split.map { |w| w[0] }.join.upcase, net_direction: direction,
           net_amount: amount, primary_debt: double(id: debt_id))
  end

  let(:owed) { [ relation("Ama Koffi", "lent", 30_000.0, "d1"), relation("Kofi", "lent", 10_000.0, "d2") ] }
  let(:owing) { [ relation("Yao", "borrowed", 15_000.0, "d3") ] }
  let(:relations) { owing + owed }
  let(:rendered) { render_inline(described_class.new(relations: relations)) }

  context "without relations" do
    let(:relations) { [] }

    it "renders nothing" do
      expect(rendered.to_html.strip).to be_empty
    end
  end

  it "anchors the section for the spending card's lent line" do
    expect(rendered.at_css("h2#analyses-between").text).to eq("Between you and others")
  end

  it "nets both sides into a signed hero" do
    hero = rendered.at_css(".analyses-hero")
    expect(hero["class"]).to include("analyses-hero--positive")
    expect(hero.text.squish).to match(/\A\+.25,000/)
  end

  it "shows the two gross totals" do
    expect(rendered.at_css(".analyses-debt-chip--in .analyses-debt-chip__value").text).to include("40,000")
    expect(rendered.at_css(".analyses-debt-chip--out .analyses-debt-chip__value").text).to include("15,000")
  end

  it "lists who owes you, biggest first, with bars relative to the biggest" do
    lists = rendered.css(".analyses-row")
    expect(lists.size).to eq(2)
    expect(lists[0].at_css(".analyses-debt-list__title").text).to eq("Who owes you")
    people = lists[0].css("a.analyses-person")
    expect(people.map { |a| a.at_css(".analyses-person__name").text }).to eq([ "Ama Koffi", "Kofi" ])
    expect(people.map { |a| a.at_css(".analyses-person__bar span")["style"] }).to eq([ "width: 100.0%;", "width: 33.3%;" ])
    expect(people.first.at_css(".analyses-person__avatar").text).to eq("AK")
    expect(people.first.at_css(".analyses-person__avatar")["class"]).to include("analyses-person__avatar--in")
  end

  it "lists whom you owe on the out side" do
    list = rendered.css(".analyses-row")[1]
    expect(list.at_css(".analyses-debt-list__title").text).to eq("Whom you owe")
    expect(list.at_css(".analyses-person__avatar")["class"]).to include("analyses-person__avatar--out")
    expect(list.at_css(".analyses-person__bar")["class"]).to include("analyses-person__bar--out")
  end

  it "links each person to their primary debt at the top level" do
    links = rendered.css("a.analyses-person")
    expect(links.map { |a| a["href"] }).to eq([ "/debts/d1", "/debts/d2", "/debts/d3" ])
    expect(links.map { |a| a["data-turbo-frame"] }.uniq).to eq([ "_top" ])
  end

  context "when you owe more than you are owed" do
    let(:owing) { [ relation("Yao", "borrowed", 55_000.0, "d3") ] }

    it "turns the hero negative" do
      hero = rendered.at_css(".analyses-hero")
      expect(hero["class"]).to include("analyses-hero--negative")
      expect(hero.text.squish).to match(/\A−.15,000/)
    end
  end

  context "with a settled borrowed relation" do
    let(:owing) { [ relation("Yao", "borrowed", 0.0, "d3") ] }

    it "leaves it out of the lists" do
      expect(rendered.css(".analyses-row").size).to eq(1)
      expect(rendered.at_css(".analyses-debt-chip--out .analyses-debt-chip__value").text).to include("0")
    end
  end
end
