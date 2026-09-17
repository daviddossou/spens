# frozen_string_literal: true

require "rails_helper"

RSpec.describe Debts::WrittenOffComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before { allow(vc_test_controller).to receive(:current_space).and_return(space) }

  it "strikes a written-off loan with the date and what did come back" do
    debt = create(:debt, space: space, status: "written_off", total_lent: 50_000, total_reimbursed: 15_000,
                         updated_at: Time.zone.local(2026, 9, 3, 12))
    rendered = render_inline(described_class.new(debt: debt))
    expect(rendered.at_css(".debt-abandoned")["class"]).to include("debt-abandoned--lent")
    expect(rendered.at_css(".debt-abandoned__badge").text).to eq("Written off")
    expect(rendered.at_css(".debt-abandoned__amount").text).to include("35,000")
    note = rendered.at_css(".debt-abandoned__note").text.squish
    expect(note).to include("You stopped counting on it on September 03, 2026")
    expect(note).to include("Owed to you")
    expect(rendered.at_css(".debt-abandoned__detail").text).to include("15,000")
    expect(rendered.at_css(".debt-abandoned__detail").text).to include("recovered of")
    expect(rendered.text).not_to include("translation missing")
  end

  it "reads a forgiven debt with no detail when nothing was repaid" do
    debt = create(:debt, :borrowed, space: space, status: "written_off", total_lent: 8_000)
    rendered = render_inline(described_class.new(debt: debt))
    expect(rendered.at_css(".debt-abandoned")["class"]).to include("debt-abandoned--borrowed")
    expect(rendered.at_css(".debt-abandoned__badge").text).to eq("Debt forgiven")
    expect(rendered.at_css(".debt-abandoned__amount").text).to include("8,000")
    expect(rendered.at_css(".debt-abandoned__note").text.squish).to include("You cleared this debt on")
    expect(rendered.css(".debt-abandoned__detail")).to be_empty
  end
end
