# frozen_string_literal: true

require "rails_helper"

RSpec.describe FindOrCreateTransactionTypeService do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  def call(name, kind = "expense")
    described_class.new(space, name, kind).call
  end

  describe "a canonical category name (picked suggestion)" do
    it "materialises the node and links it to its parent" do
      type = call("🛒 Groceries")
      expect(type.template_key).to eq("groceries")
      expect(type.parent.template_key).to eq("food_groceries")
      expect(type.kind).to eq("expense")
    end

    it "matches an emoji-less / accented name to the canonical node" do
      expect(call("provisions").template_key).to eq("groceries") # fr name "🛒 Provisions"
    end

    it "does not duplicate on a second call" do
      first = call("🛒 Groceries")
      expect { call("🛒 Groceries") }.not_to change(space.transaction_types, :count)
      expect(call("🛒 Groceries")).to eq(first)
    end

    it "shares one parent row across sibling subcategories" do
      groceries_parent = call("🛒 Groceries").parent
      provisions_parent = call("📦 Monthly provisions").parent
      expect(provisions_parent).to eq(groceries_parent)
    end

    it "adopts an existing same-named row instead of duplicating it" do
      legacy = space.transaction_types.create!(name: "🛒 Groceries", kind: "expense", budget_goal: 0)
      type = call("🛒 Groceries")
      expect(type).to eq(legacy)
      expect(legacy.reload.template_key).to eq("groceries")
      expect(legacy.parent.template_key).to eq("food_groceries")
    end

    it "lets a transaction attach directly to a parent category" do
      type = call("🚍 Transport")
      expect(type.template_key).to eq("transport")
      expect(type).to be_root
    end
  end

  describe "free-text category (no taxonomy match)" do
    it "creates a plain category with no parent (unchanged behaviour)" do
      type = call("My Random Thing")
      expect(type.template_key).to be_nil
      expect(type.parent).to be_nil
      expect(type.name).to eq("My Random Thing")
    end

    it "reuses an existing free-text category case-insensitively" do
      first = call("Side Project")
      expect(call("side project")).to eq(first)
    end
  end

  describe "non-categorised kinds (debt / transfer)" do
    it "creates the type without a parent even if the name resembles a category" do
      type = call("Groceries", "debt_in")
      expect(type.parent).to be_nil
      expect(type.template_key).to be_nil
    end
  end
end
