# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::LlmParser do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  # Stub the HTTP boundary; exercise the JSON -> Result mapping + category resolution.
  def parse_with(json)
    parser = described_class.new(space: space, locale: :en)
    allow(parser).to receive(:complete).and_return(json)
    parser.parse("whatever")
  end

  before { allow(described_class).to receive(:enabled?).and_return(true) }

  it "resolves the model's category guess to a taxonomy key" do
    result = parse_with("kind" => "expense", "amount" => 2000, "category" => "groceries", "phrase" => "ndogou")

    expect(result.category_key).to eq("groceries")
    expect(result.category_name).to eq(TransactionTaxonomy.name("groceries", :en))
    expect(result.amount).to eq(2000)
    expect(result.phrase).to eq("ndogou")
  end

  it "leaves the category unresolved when the guess isn't a known node" do
    result = parse_with("kind" => "expense", "amount" => 1000, "category" => "florble", "phrase" => "florble")

    expect(result.category_key).to be_nil
    expect(result.category_name).to be_nil
  end

  it "drops a non-positive amount" do
    result = parse_with("kind" => "expense", "amount" => 0, "category" => "groceries", "phrase" => "x")
    expect(result.amount).to be_nil
  end

  it "extracts the two accounts for a transfer" do
    result = parse_with("kind" => "transfer", "amount" => 50_000, "from_account" => "Orabank", "to_account" => "Wave")
    expect(result.kind).to eq("transfer")
    expect(result.from_account).to eq("Orabank")
    expect(result.to_account).to eq("Wave")
  end

  it "extracts the person and direction for a debt, normalising the direction" do
    result = parse_with("kind" => "debt", "amount" => 2000, "person" => "Ali", "direction" => "Lent")
    expect(result.kind).to eq("debt")
    expect(result.person).to eq("Ali")
    expect(result.direction).to eq("lent")
  end

  it "drops an unrecognised direction" do
    result = parse_with("kind" => "debt", "amount" => 2000, "person" => "Ali", "direction" => "??")
    expect(result.direction).to be_nil
  end

  it "returns nil when disabled" do
    allow(described_class).to receive(:enabled?).and_return(false)
    expect(described_class.new(space: space, locale: :en).parse("2000 zem")).to be_nil
  end

  describe "the system prompt" do
    it "is built from the taxonomy + the space currency, with no hardcoded vocabulary" do
      space.update!(currency: "GHS")
      prompt = described_class.new(space: space, locale: :en).send(:system_prompt)

      # real taxonomy parent categories (not hand-typed ones)
      a_parent = TransactionTaxonomy.name(TransactionTaxonomy.parent_keys("expense").first, :en)
                                    .sub(/\A[^[:alnum:]]+/, "").strip
      expect(prompt).to include(a_parent)

      # the space's currency, not a baked-in "CFA"
      expect(prompt).to include("GHS")
      expect(prompt).not_to include("CFA")

      # the alias dictionary's job stays in the alias dictionary
      expect(prompt).not_to include("zem")
    end

    it "localises the category labels (FR)" do
      prompt = described_class.new(space: space, locale: :fr).send(:system_prompt)
      fr_parent = TransactionTaxonomy.name(TransactionTaxonomy.parent_keys("income").first, :fr)
                                     .sub(/\A[^[:alnum:]]+/, "").strip
      expect(prompt).to include(fr_parent)
    end
  end
end
