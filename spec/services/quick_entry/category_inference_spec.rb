# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::CategoryInference do
  def infer(text) = described_class.infer(text)

  it "resolves a merchant/mode alias to its taxonomy key" do
    expect(infer("2000 zem")).to eq("moto_taxi")
    expect(infer("I paid at Carrefour")).to eq("groceries")
  end

  it "resolves a taxonomy display name (EN and FR)" do
    expect(infer("groceries run")).to eq("groceries")
    expect(infer("reçu mon salaire")).to eq("salary")
  end

  it "is accent- and case-insensitive" do
    expect(infer("CARREFOUR")).to eq("groceries")
  end

  it "prefers the most specific (longest) match" do
    # "public transport" (a name) should beat the bare word "transport" (a parent name)
    expect(infer("took public transport today")).to eq("public_transport")
  end

  it "returns nil when nothing matches" do
    expect(infer("two thousand")).to be_nil
  end

  it "resolves a learned alias the built-ins don't know" do
    expect(infer("2000 zoomzoom")).to be_nil

    LearnedAlias.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "edit_diff")

    expect(infer("2000 zoomzoom")).to eq("moto_taxi")
  end
end
