# frozen_string_literal: true

require "rails_helper"

RSpec.describe Debts::ClosedStateComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before { allow(vc_test_controller).to receive(:current_space).and_return(space) }

  it "reads a settled loan as fully repaid" do
    debt = create(:debt, :paid, space: space, total_lent: 1_000)
    rendered = render_inline(described_class.new(debt: debt))
    expect(rendered.at_css(".debt-closed-card")["class"]).to include("debt-closed-card--paid")
    expect(rendered.at_css(".debt-closed-card__badge").text).to eq("Settled")
    expect(rendered.at_css(".debt-closed-card__amount").text).to include("1,000")
    expect(rendered.at_css(".debt-closed-card__label").text).to eq("repaid")
    expect(rendered.at_css(".debt-closed-card__detail").text).to include("1,000")
    expect(rendered.at_css(".debt-closed-card__detail").text).to include("recovered of")
    expect(rendered.text).not_to include("translation missing")
  end

  it "reads a written-off loan by what was not recovered" do
    debt = create(:debt, space: space, status: "written_off", total_lent: 1_000, total_reimbursed: 300)
    rendered = render_inline(described_class.new(debt: debt))
    expect(rendered.at_css(".debt-closed-card")["class"]).to include("debt-closed-card--written_off")
    expect(rendered.at_css(".debt-closed-card__badge").text).to eq("Written off")
    expect(rendered.at_css(".debt-closed-card__amount").text).to include("700")
    expect(rendered.at_css(".debt-closed-card__label").text).to eq("not recovered")
    expect(rendered.at_css(".debt-closed-card__detail").text).to include("300")
    expect(rendered.at_css(".debt-closed-card__detail").text).to include("recovered of")
  end

  it "reads a forgiven debt with no detail when nothing had moved" do
    debt = create(:debt, :borrowed, space: space, status: "written_off", total_lent: 5_000)
    rendered = render_inline(described_class.new(debt: debt))
    expect(rendered.at_css(".debt-closed-card__badge").text).to eq("Debt forgiven")
    expect(rendered.at_css(".debt-closed-card__amount").text).to include("5,000")
    expect(rendered.at_css(".debt-closed-card__label").text).to eq("written off")
    expect(rendered.css(".debt-closed-card__detail")).to be_empty
  end
end
