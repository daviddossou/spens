# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::PhraseExtractor do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  def extract(text, locale: :en, exclude: [])
    described_class.call(text: text, locale: locale, space: space, exclude: exclude)
  end

  it "returns the residual word the rules don't already know" do
    expect(extract("2000 zoomzoom")).to eq("zoomzoom")
  end

  it "drops numbers, keywords, prepositions and stopwords" do
    expect(extract("j'ai dépanné de 2000", locale: :fr)).to eq("dépanné")
  end

  it "excludes names the caller already resolved (person/accounts)" do
    expect(extract("j'ai dépanné Ali de 2000", locale: :fr, exclude: [ "Ali" ])).to eq("dépanné")
  end

  it "returns nil when nothing significant remains" do
    expect(extract("transferred 2000")).to be_nil
  end

  it "caps the run at three words" do
    expect(extract("alpha beta gamma delta").split.size).to eq(3)
  end

  it "drops generic transaction verbs like 'achat'" do
    expect(extract("achat de punaise pour la maison", locale: :fr)).to eq("punaise")
  end

  it "drops month names so dates never become expressions" do
    expect(extract("approvisionnement 2300 le 16 juin 2026", locale: :fr)).to eq("approvisionnement")
  end

  it "drops the space's own transaction type names" do
    create(:transaction_type, space: space, name: "Contribution DD", kind: :expense)
    expect(extract("contribution zoomzoom 500", locale: :fr)).to eq("zoomzoom")
  end
end
