# frozen_string_literal: true

require "rails_helper"

# Tour 28c: one formatter for every displayed amount. Tour 32d: a column's
# format is decided by its smallest value, and the unit is spaced off the number.
RSpec.describe MoneyHelper, type: :helper do
  NBSP = MoneyHelper::NBSP
  NNBSP = MoneyHelper::NNBSP # before the k/M unit
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

    it "spaces the unit off the number so it never reads as an identifier" do
      expect(helper.money(40_000, "USD", compact: true)).to eq("40#{NNBSP}k#{NBSP}$")
      expect(helper.money(145_000, "USD", compact: true)).to eq("145#{NNBSP}k#{NBSP}$")
      expect(helper.money(2_000_000, "USD", compact: true)).to eq("2#{NNBSP}M#{NBSP}$")
    end

    it "keeps at most one meaningful decimal in abbreviations" do
      expect(helper.money(1_200_000, "USD", compact: true)).to eq("1.2#{NNBSP}M#{NBSP}$")
      expect(helper.money(12_500, "USD", compact: true)).to eq("12.5#{NNBSP}k#{NBSP}$")
      I18n.with_locale(:fr) do
        expect(helper.money(1_200_000, "XOF", compact: true)).to eq("1,2#{NNBSP}M#{NBSP}FCFA")
      end
    end

    it "shows the full number outside compact contexts, whatever the size" do
      expect(helper.money(1_200_000, "USD")).to eq("1,200,000#{NBSP}$")
    end
  end

  describe "#money_column" do
    it "lets the SMALLEST value decide: one small amount puts the column in exact" do
      expect(helper.money_column([ 105_000, 35_000, 2_500 ], "USD", compact: true))
        .to eq([ "105,000#{NBSP}$", "35,000#{NBSP}$", "2,500#{NBSP}$" ])
    end

    it "abbreviates only when every amount clears the floor" do
      expect(helper.money_column([ 105_000, 35_000 ], "USD", compact: true))
        .to eq([ "105#{NNBSP}k#{NBSP}$", "35#{NNBSP}k#{NBSP}$" ])
    end

    it "treats a real zero as a small amount — it holds the column exact" do
      expect(helper.money_column([ 500_000, 0 ], "USD", compact: true))
        .to eq([ "500,000#{NBSP}$", "0#{NBSP}$" ])
    end

    it "lets a nil abstain rather than decide" do
      expect(helper.money_column([ 500_000, nil ], "USD", compact: true))
        .to eq([ "500#{NNBSP}k#{NBSP}$", "—" ])
    end

    it "stays exact when the column never asked to abbreviate" do
      expect(helper.money_column([ 94_000, 96_000 ], "USD"))
        .to eq([ "94,000#{NBSP}$", "96,000#{NBSP}$" ])
    end
  end

  describe "#money_pair" do
    it "is a two-value column — the smaller side decides" do
      expect(helper.money_pair(5_000, 500_000, "USD", compact: true))
        .to eq([ "5,000#{NBSP}$", "500,000#{NBSP}$" ])
    end
  end
end
