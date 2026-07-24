# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaxonomyNode do
  after { TransactionTaxonomy.reload! }

  def create_node(attrs = {})
    described_class.create!({ key: "test_parent", kind: "expense", name_en: "Test", name_fr: "Test" }.merge(attrs))
  end

  it "validates key format and uniqueness" do
    create_node
    expect(described_class.new(key: "test_parent", kind: "expense", name_en: "X", name_fr: "X")).not_to be_valid
    expect(described_class.new(key: "Bad Key!", kind: "expense", name_en: "X", name_fr: "X")).not_to be_valid
  end

  it "refuses key changes after create" do
    node = create_node
    node.key = "renamed"
    expect(node).not_to be_valid
  end

  it "requires the parent to be an existing parent of the same kind" do
    create_node(key: "p_expense", kind: "expense")
    expect(described_class.new(key: "c1", kind: "expense", parent_key: "p_expense", name_en: "X", name_fr: "X")).to be_valid
    expect(described_class.new(key: "c2", kind: "income", parent_key: "p_expense", name_en: "X", name_fr: "X")).not_to be_valid
    expect(described_class.new(key: "c3", kind: "expense", parent_key: "missing", name_en: "X", name_fr: "X")).not_to be_valid
  end

  it "blocks destroy when referenced by a transaction type or when it has children" do
    parent = create_node(key: "p_used", kind: "expense")
    child = create_node(key: "c_used", kind: "expense", parent_key: "p_used")
    expect(parent.destroy).to be(false)

    space = create(:space)
    create(:transaction_type, space: space, template_key: "c_used")
    expect(child.destroy).to be(false)
  end

  it "destroys an unreferenced childless node" do
    node = create_node(key: "p_free")
    expect(node.destroy).to be_truthy
  end
end
