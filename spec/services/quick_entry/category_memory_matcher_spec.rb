# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::CategoryMemoryMatcher do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  def remember(tokens, key)
    CategoryMemory.remember(space: space, tokens: tokens, taxonomy_key: key)
  end

  it "recalls by token overlap regardless of order and subsets" do
    remember(%w[metro train ticket], "public_transport")

    expect(described_class.match("Ticket metro 500", space: space)).to eq("public_transport")
    expect(described_class.match("train ticket", space: space)).to eq("public_transport")
  end

  it "matches on a single distinctive token unique to one memory" do
    remember(%w[metro train ticket], "public_transport")
    remember(%w[fal credits], "business_work_expense")

    expect(described_class.match("metro pass", space: space)).to eq("public_transport")
  end

  it "refuses a single banal shared token" do
    remember(%w[ticket cinema], "outings")
    remember(%w[ticket train], "public_transport")

    # "ticket" appears in two memories -> not distinctive, one shared token isn't enough.
    expect(described_class.match("ticket", space: space)).to be_nil
  end

  it "prefers the memory covering more of its distinctive weight" do
    remember(%w[cinema popcorn ticket], "outings")
    remember(%w[metro train ticket], "public_transport")

    expect(described_class.match("popcorn cinema soir", space: space)).to eq("outings")
  end

  it "returns nil without a space or without memories" do
    expect(described_class.match("metro", space: nil)).to be_nil
    expect(described_class.match("metro", space: space)).to be_nil
  end

  it "sits between personal aliases and built-ins in CategoryInference" do
    remember(%w[metro train ticket], "public_transport")

    expect(QuickEntry::CategoryInference.infer("ticket metro", space: space)).to eq("public_transport")
    # The space's memory outranks a built-in alias hit ("train" -> flights_tickets).
    expect(QuickEntry::CategoryInference.infer("train ticket", space: space)).to eq("public_transport")

    # But an exact personal alias still wins over the memory.
    LearnedAlias.personal_teach(space: space, phrase: "metro", taxonomy_key: "outings")
    expect(QuickEntry::CategoryInference.infer("ticket metro", space: space)).to eq("outings")
  end

  it "last correction wins and confirmations strengthen a memory" do
    remember(%w[metro train ticket], "public_transport")
    remember(%w[metro train ticket], "public_transport")
    row = remember(%w[metro train ticket], "outings")

    expect(row.reload).to have_attributes(taxonomy_key: "outings", confirmations: 1)
    expect(CategoryMemory.where(space: space).count).to eq(1)
  end
end
