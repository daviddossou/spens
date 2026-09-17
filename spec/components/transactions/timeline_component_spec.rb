# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::TimelineComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:account) { create(:account, space: space) }
  let(:expense_type) { create(:transaction_type, space: space, kind: "expense") }
  let(:transfer_type) { create(:transaction_type, space: space, kind: "transfer_in") }
  let(:today) { Date.new(2026, 3, 5) }
  let(:yesterday) { Date.new(2026, 3, 4) }
  let(:grouped_transactions) do
    {
      today => [ create(:transaction, space: space, account: account, transaction_type: expense_type, amount: -1_000, transaction_date: today) ],
      yesterday => [ create(:transaction, space: space, account: account, transaction_type: transfer_type, amount: 5_000, transaction_date: yesterday) ]
    }
  end

  before { stub_current_space(space) }

  it "renders one day group per date, in order" do
    rendered = render_inline(described_class.new(grouped_transactions: grouped_transactions))
    expect(rendered.css(".transaction-group__date").map(&:text)).to eq([ "March 05, 2026", "March 04, 2026" ])
    expect(rendered.css("a.transaction-item").size).to eq(2)
  end

  it "totals per space by default, leaving transfers out" do
    rendered = render_inline(described_class.new(grouped_transactions: grouped_transactions))
    expect(rendered.css(".transaction-group__total").map(&:text)).to eq([ "− 1,000 FCFA", "0 FCFA" ])
  end

  it "passes the account scope down so transfers count" do
    rendered = render_inline(described_class.new(grouped_transactions: grouped_transactions, day_total_scope: :account))
    expect(rendered.css(".transaction-group__total").map(&:text).last).to eq("+ 5,000 FCFA")
  end

  it "renders nothing for an empty timeline" do
    rendered = render_inline(described_class.new(grouped_transactions: {}))
    expect(rendered.to_html.strip).to be_empty
  end
end
