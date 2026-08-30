# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::AnthropicParser do
  let(:space) { create(:space) }
  subject(:parser) { described_class.new(space: space, locale: :fr) }

  # Enable the parser and stub the HTTP call, so nothing hits the network.
  before do
    allow(described_class).to receive(:config).and_return({ api_key: "test-key", model: "claude-haiku-4-5-20251001" })
  end

  def stub_tool_use(input)
    allow_any_instance_of(described_class).to receive(:post_json).and_return(
      "content" => [ { "type" => "tool_use", "name" => "record_entry", "input" => input } ]
    )
  end

  describe ".enabled?" do
    it "is true when an api key is configured" do
      expect(described_class.enabled?).to be(true)
    end

    it "is false without a key" do
      allow(described_class).to receive(:config).and_return({})
      expect(described_class.enabled?).to be(false)
    end
  end

  describe "#parse" do
    it "resolves the model's category label to a taxonomy key and keeps the salient phrase" do
      stub_tool_use("kind" => "expense", "amount" => 5000, "category" => "Transport", "phrase" => "coca")

      result = parser.parse("achat coca 5000")

      expect(result.kind).to eq("expense")
      expect(result.amount).to eq(5000.0)
      expect(result.category_key).to eq("transport")
      expect(result.category_name).to be_present
      expect(result.phrase).to eq("coca")
    end

    it "strips the amount from the note when the model leaves it in" do
      stub_tool_use("kind" => "expense", "amount" => 500, "category" => "Transport", "phrase" => "sprite 500")

      expect(parser.parse("achat sprite 500").phrase).to eq("sprite")
    end

    it "passes through person and direction for a debt" do
      stub_tool_use("kind" => "debt", "amount" => 30000, "person" => "Marcellin", "direction" => "lent")

      result = parser.parse("prêté 30000 à Marcellin")

      expect(result.kind).to eq("debt")
      expect(result.person).to eq("Marcellin")
      expect(result.direction).to eq("lent")
    end

    it "leaves the category nil when the label matches nothing (never invents one)" do
      stub_tool_use("kind" => "expense", "amount" => 1000, "category" => "Zorglub", "phrase" => "zorglub")

      result = parser.parse("zorglub 1000")

      expect(result.category_key).to be_nil
      expect(result.category_name).to be_nil
    end

    it "returns nil (rules-only fallback) when disabled" do
      allow(described_class).to receive(:config).and_return({})
      expect(parser.parse("achat coca 5000")).to be_nil
    end
  end
end
