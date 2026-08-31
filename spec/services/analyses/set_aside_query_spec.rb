# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::SetAsideQuery do
  let(:space) { create(:space) }
  let(:savings) { create(:account, space: space, name: "Épargne", set_aside: true) }
  let(:everyday) { create(:account, space: space, name: "Courant", set_aside: false) }
  subject(:query) { described_class.new(space: space) }

  def move(kind, amount, account:, on: Date.current)
    type = space.transaction_types.find_by(kind: kind) ||
           create(:transaction_type, space: space, kind: kind, name: "T #{kind}")
    create(:transaction, space: space, account: account, transaction_type: type,
                         amount: kind == "transfer_out" ? -amount : amount, transaction_date: on)
  end

  it "nets in minus out on set-aside accounts; everyday accounts don't count" do
    move("transfer_in", 50_000, account: savings)
    move("transfer_out", 10_000, account: savings)
    move("transfer_in", 99_000, account: everyday)

    expect(query.monthly_net(Date.current)).to eq(40_000)
  end

  it "counts the consecutive positive months as a streak" do
    bom = Date.current.beginning_of_month
    [ bom, bom << 1, bom << 2 ].each { |m| move("transfer_in", 10_000, account: savings, on: m) }
    move("transfer_in", 5_000, account: savings, on: bom << 4) # gap at m-3 breaks it

    expect(query.streak).to eq(3)
    expect(query.last_three.map(&:last)).to eq([ 10_000, 10_000, 10_000 ])
  end

  it "knows whether any set-aside account exists" do
    expect(query.any_account?).to be(false)
    savings
    expect(described_class.new(space: space).any_account?).to be(true)
  end
end
