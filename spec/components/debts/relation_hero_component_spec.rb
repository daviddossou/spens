# frozen_string_literal: true

require "rails_helper"

RSpec.describe Debts::RelationHeroComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before { allow(vc_test_controller).to receive(:current_space).and_return(space) }
  let(:lent) { create(:debt, space: space, name: "Myri", total_lent: 100_000) }
  let(:borrowed) { create(:debt, :borrowed, space: space, name: "Myri", total_lent: 30_000) }
  let(:relation) { DebtRelation.new(space: space, name: "Myri", debts: [ lent, borrowed ]) }

  it "nets the two sides on the side they owe" do
    rendered = render_inline(described_class.new(debt: lent, relation: relation))
    expect(rendered.at_css(".debt-hero")["class"]).to include("debt-hero--lent")
    expect(rendered.at_css(".debt-hero__label").text).to eq("Myri owes you")
    expect(rendered.at_css(".debt-hero__amount").text).to include("70,000")
    expect(rendered.at_css(".debt-hero__progress").text).to eq("after offsetting both sides")
    expect(rendered.text).not_to include("translation missing")
  end

  it "lists both gross sub-totals" do
    rendered = render_inline(described_class.new(debt: lent, relation: relation))
    cells = rendered.css(".debt-subtotals__cell")
    expect(cells[0].at_css(".debt-subtotals__label").text).to eq("They owe you")
    expect(cells[0].at_css(".debt-subtotals__value--lent").text).to include("100,000")
    expect(cells[1].at_css(".debt-subtotals__label").text).to eq("You owe them")
    expect(cells[1].at_css(".debt-subtotals__value--borrowed").text).to include("30,000")
  end

  it "flips when the net is against me" do
    lent.update!(total_lent: 10_000)
    rendered = render_inline(described_class.new(debt: borrowed, relation: DebtRelation.new(space: space, name: "Myri", debts: [ lent, borrowed ])))
    expect(rendered.at_css(".debt-hero")["class"]).to include("debt-hero--borrowed")
    expect(rendered.at_css(".debt-hero__label").text).to eq("You owe Myri")
    expect(rendered.at_css(".debt-hero__amount").text).to include("20,000")
  end
end
