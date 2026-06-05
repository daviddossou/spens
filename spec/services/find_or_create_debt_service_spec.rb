# frozen_string_literal: true

require "rails_helper"

RSpec.describe FindOrCreateDebtService do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  it "creates a new ongoing debt with the given name and direction" do
    expect { described_class.new(space, "Alice", "lent", user).call }
      .to change { space.debts.count }.by(1)

    debt = space.debts.last
    expect(debt).to have_attributes(name: "Alice", direction: "lent", status: "ongoing", user: user)
  end

  it "returns an existing debt instead of creating a duplicate" do
    existing = create(:debt, user: user, name: "Alice", direction: "lent")

    expect { described_class.new(space, "Alice", "lent").call }.not_to change { space.debts.count }
    expect(described_class.new(space, "Alice", "lent").call).to eq(existing)
  end

  it "matches case-insensitively and trims surrounding whitespace" do
    existing = create(:debt, user: user, name: "Alice", direction: "lent")

    expect(described_class.new(space, "  alice ", "lent").call).to eq(existing)
  end

  it "treats the same name in a different direction as a distinct debt" do
    create(:debt, user: user, name: "Eve", direction: "lent")

    expect { described_class.new(space, "Eve", "borrowed", user).call }
      .to change { space.debts.count }.by(1)
  end

  it "scopes the lookup to the given space" do
    other_space = create(:space)
    create(:debt, name: "Alice", direction: "lent", space: other_space)

    expect { described_class.new(space, "Alice", "lent").call }.to change { space.debts.count }.by(1)
  end
end
