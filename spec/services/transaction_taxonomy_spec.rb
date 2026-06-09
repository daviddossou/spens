# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionTaxonomy do
  it "loads parents for both kinds" do
    expect(described_class.parent_keys("expense")).to include("transport", "food_groceries", "transaction_fees")
    expect(described_class.parent_keys("income")).to include("salary_employment", "business_trade")
  end

  it "maps a subcategory to its parent and kind" do
    expect(described_class.parent_key("moto_taxi")).to eq("transport")
    expect(described_class.kind_of("moto_taxi")).to eq("expense")
    expect(described_class.parent?("transport")).to be(true)
    expect(described_class.parent?("moto_taxi")).to be(false)
  end

  it "returns localized names" do
    expect(described_class.name("groceries", :en)).to eq("🛒 Groceries")
    expect(described_class.name("groceries", :fr)).to eq("🛒 Provisions")
  end

  it "resolves a display name (emoji/accents ignored) back to its key" do
    expect(described_class.key_for_name("🛒 Groceries")).to eq("groceries")
    expect(described_class.key_for_name("provisions")).to eq("groceries")
  end

  it "knows the default parent per kind" do
    expect(described_class.default_parent_key("expense")).to eq("other_expense")
    expect(described_class.default_parent_key("income")).to eq("other_income")
  end

  it "lists child keys of a parent" do
    expect(described_class.child_keys("electricity_water")).to contain_exactly("electricity", "water")
  end

  it "gives every node a name in both languages" do
    described_class.nodes.each do |key, node|
      expect(node["en"]).to be_present, "#{key} missing EN name"
      expect(node["fr"]).to be_present, "#{key} missing FR name"
    end
  end
end
