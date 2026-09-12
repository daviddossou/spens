# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::NoteLabel do
  def label(note, account: nil)
    described_class.call(note, account_name: account)
  end

  it "drops the amount, the account and a date word, keeping the user's words" do
    expect(label("j'ai payé 19 la pharmacie hier sur trade republic", account: "Trade Republic")).to eq("Pharmacie")
  end

  it "keeps a multi-word detail as typed, capitalised" do
    expect(label("déjeuner chez Fatou 2500 fcfa wave", account: "Wave")).to eq("Déjeuner chez Fatou")
  end

  it "handles English verbs, suffix amounts and numeric dates" do
    expect(label("paid 5k for metro ticket on 16/06 from Bank", account: "Bank")).to eq("Metro ticket")
  end

  it "drops an amount glued to its currency symbol and a written date" do
    expect(label("EDF le 7 septembre de 60€ DD Trade Republic", account: "DD Trade Republic")).to eq("EDF")
  end

  it "returns nil when nothing useful remains" do
    expect(label("55.65 € trade republic", account: "Trade Republic")).to be_nil
    expect(label("")).to be_nil
    expect(label(nil)).to be_nil
  end

  it "caps very long notes" do
    expect(label("a" * 100).length).to eq(60)
  end
end
