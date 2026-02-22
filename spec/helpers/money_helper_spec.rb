# frozen_string_literal: true

require "rails_helper"

RSpec.describe MoneyHelper, type: :helper do
  let(:user) { create(:user, currency: "USD") }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe "#format_money" do
    it "formats zero amount" do
      expect(helper.format_money(0)).to eq("0")
      expect(helper.format_money(nil)).to eq("0")
    end

    it "formats positive amount with currency symbol" do
      result = helper.format_money(1000, "USD")
      expect(result).to eq("1,000 $")
    end

    it "formats XOF currency" do
      result = helper.format_money(5000, "XOF")
      expect(result).to eq("5,000 FCFA")
    end

    it "formats EUR currency" do
      result = helper.format_money(2500, "EUR")
      expect(result).to eq("2,500 €")
    end

    it "uses current user currency if not specified" do
      result = helper.format_money(1000)
      expect(result).to include("$")
    end

    it "formats amounts with two decimal precision" do
      result = helper.format_money(1234.56, "USD")
      expect(result).to eq("1,234.56 $")
    end

    it "uses absolute value for negative amounts" do
      result = helper.format_money(-1000, "USD")
      expect(result).to eq("1,000 $")
    end
  end

  describe "#smart_format_money" do
    it "formats small amounts without abbreviation" do
      result = helper.smart_format_money(500, "USD")
      expect(result).to eq("500 $")
    end

    it "abbreviates thousands with K" do
      result = helper.smart_format_money(5000, "USD")
      expect(result).to include("5K")
      expect(result).to include("$")
    end

    it "abbreviates millions with M" do
      result = helper.smart_format_money(5_000_000, "USD")
      expect(result).to include("5M")
    end

    it "abbreviates billions with B" do
      result = helper.smart_format_money(5_000_000_000, "USD")
      expect(result).to include("5B")
    end

    it "includes title attribute with full amount" do
      result = helper.smart_format_money(5000, "USD")
      expect(result).to include("title=")
      expect(result).to include("5,000")
    end

    it "returns span element for accessibility" do
      result = helper.smart_format_money(5000, "USD")
      expect(result).to include("<span")
      expect(result).to include("cursor-help")
      expect(result).to include('aria-label')
    end

    it "uses custom threshold" do
      result = helper.smart_format_money(500, "USD", threshold: 100)
      expect(result).to include("0.5K")
    end

    it "formats decimal abbreviations" do
      result = helper.smart_format_money(1500, "USD")
      expect(result).to include("1.5K")
    end

    it "removes .0 from whole numbers" do
      result = helper.smart_format_money(2000, "USD")
      expect(result).to include("2K")
      expect(result).not_to include("2.0K")
    end
  end

  describe "#get_currency_symbol" do
    it "returns FCFA for XOF" do
      expect(helper.get_currency_symbol("XOF")).to eq("FCFA")
    end

    it "returns FCFA for XAF" do
      expect(helper.get_currency_symbol("XAF")).to eq("FCFA")
    end

    it "returns € for EUR" do
      expect(helper.get_currency_symbol("EUR")).to eq("€")
    end

    it "returns $ for USD" do
      expect(helper.get_currency_symbol("USD")).to eq("$")
    end

    it "returns £ for GBP" do
      expect(helper.get_currency_symbol("GBP")).to eq("£")
    end

    it "returns currency code for unknown currencies" do
      expect(helper.get_currency_symbol("JPY")).to eq("JPY")
    end
  end
end
