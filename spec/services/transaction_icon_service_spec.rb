# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionIconService do
  describe ".icon_class" do
    it "returns income class for income transactions" do
      expect(described_class.icon_class("income")).to eq("transaction-item__icon--income")
    end

    it "returns expense class for expense transactions" do
      expect(described_class.icon_class("expense")).to eq("transaction-item__icon--expense")
    end

    it "returns debt class for debt_in transactions" do
      expect(described_class.icon_class("debt_in")).to eq("transaction-item__icon--debt")
    end

    it "returns debt class for debt_out transactions" do
      expect(described_class.icon_class("debt_out")).to eq("transaction-item__icon--debt")
    end

    it "returns transfer class for transfer_in transactions" do
      expect(described_class.icon_class("transfer_in")).to eq("transaction-item__icon--transfer")
    end

    it "returns transfer class for transfer_out transactions" do
      expect(described_class.icon_class("transfer_out")).to eq("transaction-item__icon--transfer")
    end

    it "supports custom scope" do
      expect(described_class.icon_class("income", scope: "custom")).to eq("custom__icon--income")
    end
  end

  describe ".amount_prefix" do
    it "returns + for income" do
      expect(described_class.amount_prefix("income")).to eq("+")
    end

    it "returns + for debt_in" do
      expect(described_class.amount_prefix("debt_in")).to eq("+")
    end

    it "returns + for transfer_in" do
      expect(described_class.amount_prefix("transfer_in")).to eq("+")
    end

    it "returns - for expense" do
      expect(described_class.amount_prefix("expense")).to eq("-")
    end

    it "returns - for debt_out" do
      expect(described_class.amount_prefix("debt_out")).to eq("-")
    end

    it "returns - for transfer_out" do
      expect(described_class.amount_prefix("transfer_out")).to eq("-")
    end
  end

  describe ".amount_class" do
    it "returns income class for income transactions" do
      expect(described_class.amount_class("income")).to eq("transaction-item__amount--income")
    end

    it "returns expense class for expense transactions" do
      expect(described_class.amount_class("expense")).to eq("transaction-item__amount--expense")
    end

    it "returns neutral class for debt transactions" do
      expect(described_class.amount_class("debt_in")).to eq("transaction-item__amount--neutral")
    end

    it "returns neutral class for transfer transactions" do
      expect(described_class.amount_class("transfer_in")).to eq("transaction-item__amount--neutral")
    end

    it "supports custom scope" do
      expect(described_class.amount_class("income", scope: "custom")).to eq("custom__amount--income")
    end
  end

  describe ".icon_svg" do
    it "returns cached SVG content for valid icon" do
      svg_content = described_class.icon_svg("income")
      expect(svg_content).to include("svg")
      expect(svg_content).to be_html_safe
    end

    it "returns empty string for non-existent icon" do
      expect(described_class.icon_svg("invalid_kind")).to eq("")
    end

    it "handles transfer by defaulting to transfer_in" do
      svg_content = described_class.icon_svg("transfer")
      expect(svg_content).to include("svg")
    end

    it "caches icon content" do
      # First call reads from file
      described_class.icon_svg("income")

      # Mock File.read to ensure it's not called again
      allow(File).to receive(:read).and_call_original

      # Second call should use cache
      described_class.icon_svg("income")

      expect(File).not_to have_received(:read)
    end
  end

  describe ".header_class" do
    it "returns income class for income" do
      expect(described_class.header_class("income")).to eq("transaction-show__header--income")
    end

    it "returns expense class for expense" do
      expect(described_class.header_class("expense")).to eq("transaction-show__header--expense")
    end

    it "returns neutral class for others" do
      expect(described_class.header_class("debt_in")).to eq("transaction-show__header--neutral")
    end
  end

  describe ".badge_class" do
    it "returns income class for income" do
      expect(described_class.badge_class("income")).to eq("transaction-show__badge--income")
    end

    it "returns expense class for expense" do
      expect(described_class.badge_class("expense")).to eq("transaction-show__badge--expense")
    end

    it "returns debt class for debt transactions" do
      expect(described_class.badge_class("debt_in")).to eq("transaction-show__badge--debt")
      expect(described_class.badge_class("debt_out")).to eq("transaction-show__badge--debt")
    end

    it "returns transfer class for transfer transactions" do
      expect(described_class.badge_class("transfer_in")).to eq("transaction-show__badge--transfer")
      expect(described_class.badge_class("transfer_out")).to eq("transaction-show__badge--transfer")
    end
  end

  describe ".clear_cache" do
    it "clears the icon cache" do
      # Load an icon to populate cache
      described_class.icon_svg("income")

      # Clear cache
      described_class.clear_cache

      # Next call should read from file again
      expect(File).to receive(:read).and_call_original
      described_class.icon_svg("income")
    end
  end
end
