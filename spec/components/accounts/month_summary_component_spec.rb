# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::MonthSummaryComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:month_in) { 250_000 }
  let(:month_out) { 80_000 }

  before { stub_current_space(space) }

  let(:rendered) { render_inline(described_class.new(month_in: month_in, month_out: month_out)) }

  it "titles the block and shows the signed net" do
    expect(rendered.at_css(".account-month__title").text).to eq("This month")
    expect(rendered.at_css(".account-month__net").text).to eq("+ 170,000 FCFA")
  end

  it "shows in and out as full amounts" do
    expect(rendered.at_css(".account-month__value--in").text).to eq("250,000 FCFA")
    expect(rendered.at_css(".account-month__value--out").text).to eq("80,000 FCFA")
    expect(rendered.css(".account-month__label").map(&:text)).to eq([ "In", "Out" ])
  end

  context "when more went out than came in" do
    let(:month_out) { 300_000 }

    it "shows a negative net" do
      expect(rendered.at_css(".account-month__net").text).to eq("− 50,000 FCFA")
    end
  end

  context "with nothing either way" do
    let(:month_in) { 0 }
    let(:month_out) { 0 }

    it "shows an unsigned zero net" do
      expect(rendered.at_css(".account-month__net").text).to eq("0 FCFA")
    end
  end
end
