# frozen_string_literal: true

require "rails_helper"

RSpec.describe Debts::ClosedHistoryComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before { allow(vc_test_controller).to receive(:current_space).and_return(space) }
  let(:settled) { create(:debt, :paid, space: space, name: "Awa", total_lent: 1_000, updated_at: Time.zone.local(2026, 8, 10, 12)) }
  let(:forgiven) { create(:debt, space: space, name: "Georges", direction: "borrowed", status: "written_off", total_lent: 5_000, updated_at: Time.zone.local(2026, 9, 2, 12)) }
  let(:closed_debts) { [ forgiven, settled ] }
  let(:closed_groups) { closed_debts.group_by { |d| DebtRelation.normalize(d.name) }.values }

  def render_history
    render_inline(described_class.new(closed_debts: closed_debts, closed_groups: closed_groups))
  end

  it "collapses the archive under a count and breakdown" do
    rendered = render_history
    expect(rendered.at_css("details.debts-closed")["open"]).to be_nil
    expect(rendered.at_css(".debts-closed__label").text.squish).to include("2 closed relations")
    expect(rendered.at_css(".debts-closed__breakdown").text).to eq("1 repaid · 1 written off")
    expect(rendered.text).not_to include("translation missing")
  end

  it "opens when the page was asked for the closed list" do
    with_request_url("/debts?closed=1") do
      expect(render_history.at_css("details.debts-closed")["open"]).not_to be_nil
    end
  end

  it "links each settled debt to its page with the settlement date" do
    row = render_history.css("a.debt-closed-row").find { |r| r["href"] == debt_path(id: settled.id) }
    expect(row.at_css(".debt-closed-row__name").text.squish).to eq("Awa")
    expect(row.at_css(".debt-closed-row__sub").text.squish).to eq("Settled on 10 August")
    expect(row.at_css(".debt-closed-row__amount").text).to include("1,000")
    expect(row.at_css(".debt-closed-row__amount")["class"]).not_to include("--struck")
    expect(row["class"]).not_to include("debt-closed-row--grouped")
  end

  it "tags and strikes a written-off debt, direction-aware" do
    row = render_history.css("a.debt-closed-row").find { |r| r["href"] == debt_path(id: forgiven.id) }
    expect(row.at_css(".debt-closed-row__tag").text).to eq("Forgiven")
    expect(row.at_css(".debt-closed-row__sub").text.squish).to eq("Forgiven on 2 September")
    expect(row.at_css(".debt-closed-row__amount")["class"]).to include("debt-closed-row__amount--struck")
  end

  context "with several closed debts for one person" do
    let(:second) { create(:debt, :paid, space: space, name: "awa", direction: "borrowed", total_lent: 2_000) }
    let(:closed_debts) { [ settled, second ] }

    it "groups them under the best-cased name and says the direction per row" do
      rendered = render_history
      group = rendered.at_css(".debt-closed-group")
      expect(group.at_css(".debt-closed-group__name").text).to eq("Awa")
      expect(group.at_css(".debt-closed-group__count").text).to eq("2 debts")
      rows = group.css("a.debt-closed-row")
      expect(rows.size).to eq(2)
      expect(rows.map { |r| r["class"] }.uniq).to eq([ "debt-closed-row debt-closed-row--grouped" ])
      expect(rows.map { |r| r.at_css(".debt-closed-row__name").text.squish }).to eq([ "", "" ])
      expect(rows[0].at_css(".debt-closed-row__sub").text.squish).to start_with("Loan · Settled on")
      expect(rows[1].at_css(".debt-closed-row__sub").text.squish).to start_with("Borrowed · Settled on")
    end
  end
end
