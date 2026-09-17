# frozen_string_literal: true

require "rails_helper"

RSpec.describe Debts::ScheduleComponent, type: :component do
  include Rails.application.routes.url_helpers

  before { allow(vc_test_controller).to receive(:current_space).and_return(nil) }

  let(:debt) { build_stubbed(:debt) }
  let(:schedule) { { monthly: 20_000, ends_on: Date.new(2027, 2, 1), installments: 4, incoming: true } }

  def render_schedule(**overrides)
    render_inline(described_class.new(debt: debt, schedule: schedule.merge(overrides)))
  end

  it "states the monthly amount, the end month and the installments left" do
    rendered = render_schedule
    expect(rendered.at_css(".debt-schedule__monthly").text.squish).to include("20,000")
    expect(rendered.at_css(".debt-schedule__monthly").text.squish).to include("a month")
    timeline = rendered.at_css(".debt-schedule__timeline").text.squish
    expect(timeline).to include("Settled in February 2027")
    expect(timeline).to include("4 installments left")
    expect(rendered.text).not_to include("translation missing")
  end

  it "singularises a last installment" do
    expect(render_schedule(installments: 1).at_css(".debt-schedule__timeline").text).to include("1 installment left")
  end

  it "opens the edit sheet in the modal frame" do
    link = render_schedule.at_css("a.debt-schedule__edit")
    expect(link["href"]).to eq(edit_debt_path(id: debt.id))
    expect(link["data-turbo-frame"]).to eq("modal")
    expect(link.text).to eq("Edit")
  end

  it "explains the budget line as expected income for a loan" do
    text = render_schedule.at_css(".debt-schedule__budget-text")
    expect(text.at_css("strong").text).to eq("expected income")
    expect(text.text).to include("20,000")
  end

  it "explains the budget line as a planned expense for a borrowed debt" do
    expect(render_schedule(incoming: false).at_css(".debt-schedule__budget-text strong").text).to eq("planned expense")
  end
end
