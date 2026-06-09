# frozen_string_literal: true

require "rails_helper"

RSpec.describe BackfillCategoryHierarchy do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  def make(name, kind: "expense")
    space.transaction_types.create!(name: name, kind: kind, budget_goal: 0)
  end

  it "files an exact canonical category with template_key + parent" do
    type = make("🛒 Groceries")
    described_class.new(space).call
    expect(type.reload.template_key).to eq("groceries")
    expect(type.parent.template_key).to eq("food_groceries")
  end

  it "groups an alias-named custom category under the right parent, keeping it a custom leaf" do
    type = make("Zem")
    described_class.new(space).call
    expect(type.reload.template_key).to be_nil
    expect(type.parent.template_key).to eq("transport")
    expect(type.name).to eq("Zem") # name untouched
  end

  it "leaves a truly-unknown category untouched" do
    type = make("Blorptastic")
    described_class.new(space).call
    expect(type.reload.template_key).to be_nil
    expect(type.parent).to be_nil
  end

  it "reuses one parent row for sibling subcategories" do
    moto = make("🛵 Moto-taxi (Zem)")
    fuel = make("⛽ Fuel")
    described_class.new(space).call
    expect(moto.reload.parent).to eq(fuel.reload.parent)
    expect(moto.parent.template_key).to eq("transport")
  end

  it "is idempotent" do
    make("🛒 Groceries")
    make("Zem")
    expect { 2.times { described_class.new(space).call } }.not_to raise_error
  end

  it "does not touch debt/transfer types" do
    type = make("Repayment Received", kind: "debt_in")
    described_class.new(space).call
    expect(type.reload.parent).to be_nil
    expect(type.template_key).to be_nil
  end
end
