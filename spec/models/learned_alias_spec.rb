# frozen_string_literal: true

require "rails_helper"

RSpec.describe LearnedAlias do
  describe ".teach" do
    it "activates a human-sourced (edit_diff) alias immediately" do
      row = described_class.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "edit_diff")

      expect(row).to be_active
      expect(row.taxonomy_key).to eq("moto_taxi")
      expect(described_class.active_index).to include("zoomzoom" => "moto_taxi")
    end

    it "keeps an AI-sourced alias as a candidate until it recurs" do
      first = described_class.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "ai")
      expect(first).to be_candidate

      again = described_class.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "ai")
      expect(again).to be_active
      expect(again.confirmations).to eq(2)
    end

    it "is gap-fill only: refuses a phrase the built-ins already resolve" do
      # "zem" is a built-in alias for moto_taxi
      expect(described_class.teach(phrase: "zem", taxonomy_key: "groceries", source: "edit_diff")).to be_nil
      expect(described_class.count).to eq(0)
    end

    it "lets a human correction override a held AI guess" do
      described_class.teach(phrase: "zoomzoom", taxonomy_key: "groceries", source: "ai")
      row = described_class.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "edit_diff")

      expect(row).to be_active
      expect(row.taxonomy_key).to eq("moto_taxi")
    end
  end
end
