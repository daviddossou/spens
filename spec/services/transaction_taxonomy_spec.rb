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

  # The examples above run against the YML fallback (empty taxonomy_nodes table).
  describe "DB-backed mode" do
    around do |example|
      described_class.reload!
      example.run
      described_class.reload!
    end

    before do
      TaxonomyNode.create!(key: "db_food", kind: "expense", name_en: "🍚 Food", name_fr: "🍚 Bouffe", position: 2)
      TaxonomyNode.create!(key: "db_transport", kind: "expense", name_en: "🚕 Rides", name_fr: "🚕 Trajets", position: 1)
      TaxonomyNode.create!(key: "db_taxi", kind: "expense", parent_key: "db_transport",
                           name_en: "Taxi", name_fr: "Taxi", position: 1)
      TaxonomyNode.create!(key: "db_zem", kind: "expense", parent_key: "db_transport",
                           name_en: "Zem", name_fr: "Zémidjan", position: 0)
    end

    it "reads from the table instead of the YML" do
      expect(described_class.parent_keys("expense")).to eq(%w[db_transport db_food])
      expect(described_class.name("db_zem", :fr)).to eq("Zémidjan")
      expect(described_class.exists?("food_groceries")).to be(false)
    end

    it "orders siblings by position" do
      expect(described_class.child_keys("db_transport")).to eq(%w[db_zem db_taxi])
    end

    it "hides inactive nodes" do
      TaxonomyNode.find_by(key: "db_taxi").update!(active: false)
      expect(described_class.exists?("db_taxi")).to be(false)
      expect(described_class.child_keys("db_transport")).to eq(%w[db_zem])
    end

    it "resolves display names back to keys" do
      expect(described_class.key_for_name("zemidjan")).to eq("db_zem")
    end
  end
end
