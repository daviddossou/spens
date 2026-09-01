# frozen_string_literal: true

require "rails_helper"

# Tour 28c: one formatter for every displayed amount.
RSpec.describe MoneyHelper, type: :helper do
  NBSP = MoneyHelper::NBSP
  FINE = " " # French thousands separator

  let(:user) { create(:user, currency: "USD") }
  let(:space) { user.spaces.first }

  before do
    allow(helper).to receive(:current_user).and_return(user)
    helper.define_singleton_method(:current_space) { nil }
    allow(helper).to receive(:current_space).and_return(space)
  end

  describe "#money" do
    it "tells a real zero apart from no data" do
      expect(helper.money(0)).to eq("0#{NBSP}$")
      expect(helper.money(nil)).to eq("—")
    end

    it "always attaches the currency with a non-breaking space" do
      expect(helper.money(1_000, "USD")).to eq("1,000#{NBSP}$")
      expect(helper.money(5_000, "XOF")).to eq("5,000#{NBSP}FCFA")
      expect(helper.money(2_500, "EUR")).to eq("2,500#{NBSP}€")
    end

    it "separates French thousands with a fine non-breaking space" do
      I18n.with_locale(:fr) do
        expect(helper.money(12_500, "XOF")).to eq("12#{FINE}500#{NBSP}FCFA")
      end
    end

    it "keeps cents only when they exist" do
      expect(helper.money(1_234.56, "USD")).to eq("1,234.56#{NBSP}$")
      expect(helper.money(60.0, "USD")).to eq("60#{NBSP}$")
    end

    it "is absolute by default, signed only on demand" do
      expect(helper.money(-1_000, "USD")).to eq("1,000#{NBSP}$")
      expect(helper.money(-1_000, "USD", sign: :auto)).to eq("−#{NBSP}1,000#{NBSP}$")
      expect(helper.money(1_000, "USD", sign: :auto)).to eq("1,000#{NBSP}$")
      expect(helper.money(1_000, "USD", sign: :always)).to eq("+#{NBSP}1,000#{NBSP}$")
      expect(helper.money(0, "USD", sign: :always)).to eq("0#{NBSP}$")
    end

    it "never abbreviates under 10 000, even compact" do
      expect(helper.money(9_999, "USD", compact: true)).to eq("9,999#{NBSP}$")
    end

    it "abbreviates compact amounts with a lowercase k, then M" do
      expect(helper.money(40_000, "USD", compact: true)).to eq("40k#{NBSP}$")
      expect(helper.money(145_000, "USD", compact: true)).to eq("145k#{NBSP}$")
      expect(helper.money(2_000_000, "USD", compact: true)).to eq("2M#{NBSP}$")
    end

    it "keeps at most one meaningful decimal in abbreviations" do
      expect(helper.money(1_200_000, "USD", compact: true)).to eq("1.2M#{NBSP}$")
      expect(helper.money(12_500, "USD", compact: true)).to eq("12.5k#{NBSP}$")
      I18n.with_locale(:fr) do
        expect(helper.money(1_200_000, "XOF", compact: true)).to eq("1,2M#{NBSP}FCFA")
      end
    end

    it "shows the full number outside compact contexts, whatever the size" do
      expect(helper.money(1_200_000, "USD")).to eq("1,200,000#{NBSP}$")
    end
  end

  describe "#money_pair" do
    it "never mixes two formats in a pair — the larger decides" do
      expect(helper.money_pair(5_000, 500_000, "USD", compact: true))
        .to eq([ "5k#{NBSP}$", "500k#{NBSP}$" ])
    end

    it "stays full when neither side reaches the floor" do
      expect(helper.money_pair(5_000, 8_000, "USD", compact: true))
        .to eq([ "5,000#{NBSP}$", "8,000#{NBSP}$" ])
    end

    it "leaves exact pairs exact" do
      expect(helper.money_pair(94_000, 96_000, "USD"))
        .to eq([ "94,000#{NBSP}$", "96,000#{NBSP}$" ])
    end
  end
end
