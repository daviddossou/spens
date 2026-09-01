# frozen_string_literal: true

require "rails_helper"

RSpec.describe Taxonomy::SyncNodes do
  after { TransactionTaxonomy.reload! }

  def tree(parent_name_fr: "Parent", child_parent: "p_one")
    { "expense" => {
        "p_one" => { "en" => "Parent", "fr" => parent_name_fr, "children" => {} },
        "p_two" => { "en" => "Second", "fr" => "Second", "children" => {} } },
      "income" => {} }.tap do |t|
      t["expense"][child_parent]["children"]["c_one"] = { "en" => "Child", "fr" => "Enfant" }
    end
  end

  it "creates parents before children so parent_key validates" do
    @tree = tree
    result = described_class.new(data: @tree).call

    expect(result.created).to eq(3)
    expect(TaxonomyNode.find_by(key: "c_one").parent_key).to eq("p_one")
  end

  it "renames a node without touching its key" do
    @tree = tree
    described_class.new(data: @tree).call

    @tree = tree(parent_name_fr: "Parent renommé")
    result = described_class.new(data: @tree).call

    expect(result.renamed).to eq(1)
    expect(TaxonomyNode.find_by(key: "p_one").name_fr).to eq("Parent renommé")
  end

  it "moves a child under another parent" do
    @tree = tree
    described_class.new(data: @tree).call

    @tree = tree(child_parent: "p_two")
    result = described_class.new(data: @tree).call

    expect(result.moved).to eq(1)
    expect(TaxonomyNode.find_by(key: "c_one").parent_key).to eq("p_two")
  end

  it "retires a dropped node instead of destroying it, so template_key keeps resolving" do
    @tree = tree
    described_class.new(data: @tree).call

    dropped = tree
    dropped["expense"]["p_one"]["children"] = {}
    @tree = dropped
    result = described_class.new(data: @tree).call

    expect(result.deactivated).to eq(1)
    node = TaxonomyNode.find_by(key: "c_one")
    expect(node).to be_present
    expect(node.active).to be(false)
  end

  it "never deactivates a protected catch-all" do
    TaxonomyNode.create!(key: "other_expense", kind: "expense", name_en: "Other", name_fr: "Autre")
    @tree = tree

    described_class.new(data: @tree).call

    expect(TaxonomyNode.find_by(key: "other_expense").active).to be(true)
  end

  it "is idempotent" do
    @tree = tree
    described_class.new(data: @tree).call
    result = described_class.new(data: @tree).call

    expect([ result.created, result.renamed, result.moved, result.deactivated ]).to all(eq(0))
  end

  describe "the shipped taxonomy" do
    it "applies cleanly and leaves no child pointing at a missing parent" do
      described_class.new.call

      orphans = TaxonomyNode.active.where.not(parent_key: nil)
                            .where.not(parent_key: TaxonomyNode.active.parents.select(:key))
      expect(orphans).to be_empty
      expect(TaxonomyNode.active.parents.where(kind: "expense").count).to eq(21)
    end
  end
end
