# frozen_string_literal: true

# == Schema Information
#
# Table name: learned_aliases
#
#  id            :uuid             not null, primary key
#  confirmations :integer          default(0), not null
#  phrase        :string           not null, indexed
#  source        :string           not null
#  state         :string           default("candidate"), not null, indexed
#  taxonomy_key  :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_learned_aliases_on_phrase  (phrase) UNIQUE
#  index_learned_aliases_on_state   (state)
#
require "rails_helper"

RSpec.describe LearnedAlias do
  describe ".teach" do
    it "starts every learned alias as a candidate — even a human edit (a human approves it later)" do
      row = described_class.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "edit_diff")

      expect(row).to be_candidate
      expect(row.taxonomy_key).to eq("moto_taxi")
      expect(described_class.active_index).to be_empty
    end

    it "strengthens (but does not activate) a candidate when it recurs" do
      first = described_class.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "ai")
      again = described_class.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "ai")

      expect(again).to be_candidate
      expect(again.confirmations).to eq(2)
    end

    it "records the strongest source seen on agreement (an edit-diff outranks an AI guess)" do
      described_class.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "ai")
      row = described_class.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "edit_diff")

      expect(row.source).to eq("edit_diff")
      expect(row.confirmations).to eq(2)
    end

    it "is gap-fill only: refuses a phrase the built-ins already resolve" do
      # "zem" is a built-in alias for moto_taxi
      expect(described_class.teach(phrase: "zem", taxonomy_key: "groceries", source: "edit_diff")).to be_nil
      expect(described_class.count).to eq(0)
    end

    it "refuses a word already living inside a built-in phrase ('contribution' vs 'contribution religieuse')" do
      expect(described_class.teach(phrase: "contribution", taxonomy_key: "savings", source: "ai")).to be_nil
      expect(described_class.count).to eq(0)
    end

    it "still accepts a genuinely novel word" do
      expect(described_class.teach(phrase: "punaise", taxonomy_key: "home_repairs", source: "edit_diff")).to be_present
    end

    it "replaces a still-pending candidate's value when a newer teaching disagrees" do
      described_class.teach(phrase: "zoomzoom", taxonomy_key: "groceries", source: "ai")
      row = described_class.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "ai")

      expect(row).to be_candidate
      expect(row.taxonomy_key).to eq("moto_taxi")
      expect(row.confirmations).to eq(1)
    end

    it "never lets an unverified relearn disturb a human-approved alias" do
      row = described_class.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "edit_diff")
      row.approve!

      described_class.teach(phrase: "zoomzoom", taxonomy_key: "groceries", source: "ai")

      expect(row.reload).to be_active
      expect(row.taxonomy_key).to eq("moto_taxi")
    end
  end

  describe ".admin_teach" do
    it "writes the mapping active immediately (the admin is the approval)" do
      row = described_class.admin_teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi")

      expect(row).to be_active
      expect(described_class.active_index).to eq("zoomzoom" => "moto_taxi")
    end

    it "retargets an existing candidate and activates it" do
      described_class.teach(phrase: "zoomzoom", taxonomy_key: "groceries", source: "ai")
      row = described_class.admin_teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi")

      expect(row).to be_active
      expect(row.taxonomy_key).to eq("moto_taxi")
    end
  end

  describe "#approve! / #reject!" do
    it "approval makes a candidate visible to the rules" do
      row = described_class.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "ai")

      expect { row.approve! }.to change { described_class.active_index }.from({}).to("zoomzoom" => "moto_taxi")
    end

    it "rejection keeps the row (so we don't relearn it) but never consults it" do
      row = described_class.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "ai")
      row.reject!

      expect(row).to be_rejected
      expect(described_class.active_index).to be_empty
    end
  end
end
