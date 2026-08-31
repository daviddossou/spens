# frozen_string_literal: true

require "rails_helper"

RSpec.describe DebtRelation do
  let(:space) { create(:space) }

  def relation_for(name)
    described_class.new(space: space, name: name)
  end

  it "nets the two directions of the same person" do
    create(:debt, space: space, name: "David", direction: "lent", total_lent: 45_000, total_reimbursed: 0)
    create(:debt, space: space, name: "David", direction: "borrowed", total_lent: 270_000, total_reimbursed: 0)

    rel = relation_for("David")
    expect(rel.owed_to_me).to eq(45_000)
    expect(rel.i_owe).to eq(270_000)
    expect(rel.net).to eq(225_000)          # positive → you owe
    expect(rel.net_direction).to eq("borrowed")
    expect(rel).to be_two_way
    expect(rel.offsettable).to eq(45_000)
  end

  it "matches a person across casing and stray spaces (one relation, one card)" do
    create(:debt, space: space, name: "Gilchrist", direction: "lent", total_lent: 35_000, total_reimbursed: 0)
    create(:debt, space: space, name: "gilchrist ", direction: "borrowed", total_lent: 150_000, total_reimbursed: 0)

    rel = relation_for("Gilchrist")
    expect(rel).to be_two_way
    expect(rel.net_amount).to eq(115_000)

    expect(described_class.all_ongoing(space).size).to eq(1)
  end

  it "reads as a plain one-directional relation when only one side has a balance" do
    create(:debt, space: space, name: "Karim", direction: "lent", total_lent: 100_000, total_reimbursed: 20_000)

    rel = relation_for("Karim")
    expect(rel).to be_single
    expect(rel).not_to be_two_way
    expect(rel.net_amount).to eq(80_000)
    expect(rel.net_direction).to eq("lent")
  end

  it "groups all ongoing debts into one relation per person" do
    create(:debt, space: space, name: "David", direction: "lent", total_lent: 45_000)
    create(:debt, space: space, name: "David", direction: "borrowed", total_lent: 270_000)
    create(:debt, space: space, name: "Karim", direction: "lent", total_lent: 100_000)

    names = described_class.all_ongoing(space).map(&:name)
    expect(names).to contain_exactly("David", "Karim")
  end
end
