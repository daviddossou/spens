# frozen_string_literal: true

require "rails_helper"

RSpec.describe CategoryAliasMatcher do
  it "matches a merchant/brand to its subcategory" do
    expect(described_class.match("Carrefour")).to eq("groceries")
    expect(described_class.match("Gozem")).to eq("ride_hailing")
    expect(described_class.match("Sonacop")).to eq("fuel")
  end

  it "is accent- and punctuation-insensitive" do
    expect(described_class.match("zémidjan")).to eq("moto_taxi")
    expect(described_class.match("zemidjan")).to eq("moto_taxi")
    expect(described_class.match("WORO-WORO")).to eq("public_transport")
    expect(described_class.match("woro woro")).to eq("public_transport")
  end

  it "matches English phrases too" do
    expect(described_class.match("income tax")).to eq("taxes")
    expect(described_class.match("haircut")).to eq("salon_beauty")
    expect(described_class.match("soap")).to eq("home_supplies")
  end

  it "returns nil for unknown or blank text" do
    expect(described_class.match("xyzzy something")).to be_nil
    expect(described_class.match(nil)).to be_nil
    expect(described_class.match("")).to be_nil
  end

  it "only points at real taxonomy subcategories" do
    keys = described_class.index.values.uniq
    expect(keys).to all(satisfy { |k| TransactionTaxonomy.exists?(k) })
  end
end
