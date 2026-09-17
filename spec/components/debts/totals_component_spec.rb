# frozen_string_literal: true

require "rails_helper"

RSpec.describe Debts::TotalsComponent, type: :component do
  before { allow(vc_test_controller).to receive(:current_space).and_return(nil) }

  def render_totals(owed_to_me: [ :myri, :ali ], i_owe: [], total_owed_to_me: 1_250_000, total_i_owe: 0)
    render_inline(described_class.new(i_owe: i_owe, owed_to_me: owed_to_me, total_i_owe: total_i_owe, total_owed_to_me: total_owed_to_me))
  end

  it "labels both sides with compact totals" do
    rendered = render_totals
    cells = rendered.css(".debts-totals__cell")
    expect(cells[0].at_css(".debts-totals__label").text).to eq("Owed to you")
    expect(cells[0].at_css(".debts-totals__value--lent").text).to include("1.3 M")
    expect(cells[1].at_css(".debts-totals__label").text).to eq("You owe")
    expect(cells[1].at_css(".debts-totals__value--borrowed").text.squish).to include("0")
    expect(rendered.text).not_to include("translation missing")
  end

  it "counts the people on each side, or says nothing is ongoing" do
    metas = render_totals.css(".debts-totals__meta").map { |m| m.text.squish }
    expect(metas).to eq([ "2 people", "nothing ongoing" ])
    expect(render_totals(i_owe: [ :one ], total_i_owe: 500).css(".debts-totals__meta").last.text.squish).to eq("1 person")
  end
end
