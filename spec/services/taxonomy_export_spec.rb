# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaxonomyExport do
  let(:space) { create(:space) }

  def type_for(key, kind: :expense, name: key)
    create(:transaction_type, space: space, kind: kind, name: name, template_key: key)
  end

  def spend_on(type, count: 1)
    count.times { create(:transaction, space: space, transaction_type: type, amount: -100) }
  end

  describe "structure" do
    subject(:payload) { described_class.call(gaps: false) }

    it "exports both kinds with parents carrying their children" do
      expect(payload[:kinds].keys).to match_array(TransactionTaxonomy::KINDS)

      transport = payload[:kinds]["expense"].find { |p| p[:key] == "transport" }
      expect(transport[:name][:fr]).to be_present
      expect(transport[:children].map { |c| c[:key] }).to include("moto_taxi", "fuel")
    end

    it "counts parents and children per kind" do
      expect(payload[:counts]["expense"][:parents]).to eq(TransactionTaxonomy.parent_keys("expense").size)
      expect(payload[:counts]["expense"][:children]).to be > payload[:counts]["expense"][:parents]
    end

    it "flags the catch-all nodes" do
      other = payload[:kinds]["expense"].find { |p| p[:key] == "other_expense" }
      expect(other[:catch_all]).to be(true)
    end

    it "restricts to a single kind when asked" do
      expect(described_class.call(kind: "income", gaps: false)[:kinds].keys).to eq([ "income" ])
    end
  end

  describe "usage" do
    it "rolls a parent's own hits together with its children's" do
      spend_on(type_for("fuel", name: "Fuel"), count: 3)
      spend_on(type_for("moto_taxi", name: "Moto"), count: 2)
      spend_on(type_for("transport", name: "Transport"), count: 1)

      transport = described_class.call(gaps: false)[:kinds]["expense"].find { |p| p[:key] == "transport" }

      expect(transport[:usage][:transactions]).to eq(1)
      expect(transport[:subtree_usage][:transactions]).to eq(6)
      expect(transport[:subtree_usage][:spaces]).to eq(1)
    end
  end

  describe "coverage" do
    it "reports the share that landed on a catch-all or an invented category" do
      spend_on(type_for("fuel", name: "Fuel"), count: 6)
      spend_on(type_for("uncategorized_expense", name: "Uncategorized"), count: 2)
      spend_on(create(:transaction_type, space: space, kind: :expense, name: "Cadeau tantine"), count: 2)

      coverage = described_class.call(gaps: false)[:coverage]

      expect(coverage[:transactions]).to eq(10)
      expect(coverage[:catch_all]).to eq(transactions: 2, percent: 20.0)
      expect(coverage[:custom_category]).to eq(transactions: 2, percent: 20.0)
      expect(coverage[:uncovered]).to eq(transactions: 4, percent: 40.0)
    end

    it "stays silent rather than dividing by zero with no transactions" do
      expect(described_class.call(gaps: false)[:coverage]).to eq(transactions: 0)
    end
  end

  describe "gaps" do
    it "lists the categories users had to invent" do
      spend_on(create(:transaction_type, space: space, kind: :expense, name: "Cotisation tontine bureau"))

      phrases = described_class.call[:gaps].map { |g| g[:display_name] }
      expect(phrases).to include("Cotisation tontine bureau")
    end

    it "is omitted when disabled" do
      expect(described_class.call(gaps: false)).not_to have_key(:gaps)
    end
  end

  describe "aliases" do
    it "attaches the vocabulary that resolves to a node" do
      LearnedAlias.admin_teach(phrase: "essence", taxonomy_key: "fuel")

      fuel = described_class.call(gaps: false)[:kinds]["expense"]
              .find { |p| p[:key] == "transport" }[:children]
              .find { |c| c[:key] == "fuel" }

      expect(fuel[:aliases][:count]).to be >= 1
      expect(fuel[:aliases][:sample]).to include("essence")
    end
  end
end
