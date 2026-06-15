# frozen_string_literal: true

# == Schema Information
#
# Table name: learned_keywords
#
#  id            :uuid             not null, primary key
#  confirmations :integer          default(0), not null
#  kind          :string           not null
#  phrase        :string           not null, indexed
#  source        :string           not null
#  state         :string           default("candidate"), not null, indexed
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_learned_keywords_on_phrase  (phrase) UNIQUE
#  index_learned_keywords_on_state   (state)
#
require "rails_helper"

RSpec.describe LearnedKeyword do
  describe ".teach" do
    it "starts a novel kind verb as a candidate, normalized" do
      row = described_class.teach(phrase: "dépanné", kind: "debt_out", source: "ai")

      expect(row).to be_candidate
      expect(row.phrase).to eq("depanne")
      expect(row.kind).to eq("debt_out")
      expect(described_class.active_index).to be_empty
    end

    it "is gap-fill only: refuses a verb the built-in kind keywords already classify" do
      # "prete" is a built-in FR debt_lent verb; "transfer" a built-in EN transfer verb.
      expect(described_class.teach(phrase: "prete", kind: "debt_out", source: "ai")).to be_nil
      expect(described_class.teach(phrase: "transfer", kind: "transfer", source: "ai")).to be_nil
      expect(described_class.count).to eq(0)
    end

    it "rejects a kind outside the structural set" do
      expect { described_class.teach(phrase: "zoomzoom", kind: "expense", source: "ai") }
        .to raise_error(ActiveRecord::RecordInvalid)
    end

    it "strengthens a recurring candidate and keeps the strongest source" do
      described_class.teach(phrase: "dépanné", kind: "debt_out", source: "ai")
      row = described_class.teach(phrase: "depanne", kind: "debt_out", source: "edit_diff")

      expect(row).to be_candidate
      expect(row.confirmations).to eq(2)
      expect(row.source).to eq("edit_diff")
    end

    it "never lets an unverified relearn disturb an approved keyword" do
      row = described_class.teach(phrase: "dépanné", kind: "debt_out", source: "ai")
      row.approve!

      described_class.teach(phrase: "depanne", kind: "transfer", source: "ai")

      expect(row.reload).to be_active
      expect(row.kind).to eq("debt_out")
    end
  end

  describe "#approve!" do
    it "makes an approved keyword visible to the parser" do
      row = described_class.teach(phrase: "dépanné", kind: "debt_out", source: "ai")

      expect { row.approve! }.to change { described_class.active_index }
        .from({}).to("depanne" => "debt_out")
    end
  end
end
