# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::PhraseInputComponent, type: :component do
  let(:text) { "" }
  let(:phrase_context_key) { :none }

  let(:rendered) { render_inline(described_class.new(text: text, phrase_context_key: phrase_context_key)) }
  let(:input) { rendered.at_css("input#phrase") }

  it "submits the phrase as `text` with the transaction form" do
    expect(input["name"]).to eq("text")
    expect(input["form"]).to eq("transaction-form")
    expect(input["type"]).to eq("text")
    expect(input["value"]).to eq("")
    expect(input.has_attribute?("autofocus")).to be(true)
    expect(input["autocomplete"]).to eq("off")
    expect(input["enterkeyhint"]).to eq("done")
  end

  it "is wired to the phrase-fill and dictation controllers" do
    expect(input["data-phrase-fill-target"]).to eq("input")
    expect(input["data-dictation-target"]).to eq("input")
    expect(input["data-action"]).to eq("input->phrase-fill#type keydown->phrase-fill#submitOnEnter")
    field = rendered.at_css(".phrase-band__field")
    expect(field["data-controller"]).to eq("dictation")
    expect(field["data-dictation-lang-value"]).to eq("en-US")
    expect(field["data-dictation-idle-label-value"]).to eq("Dictate the transaction")
    expect(field["data-dictation-listening-label-value"]).to eq("Listening, tap to stop")
  end

  it "labels the field and shows the generic placeholder" do
    expect(input["aria-label"]).to eq("Describe your transaction")
    expect(input["placeholder"]).to eq("e.g. 2000 zem wallet, or 5k groceries")
  end

  it "ships a hidden mic toggle and the help and status lines" do
    mic = rendered.at_css("button.phrase-band__mic")
    expect(mic.has_attribute?("hidden")).to be(true)
    expect(mic["aria-pressed"]).to eq("false")
    expect(mic["aria-label"]).to eq("Dictate the transaction")
    expect(mic["data-action"]).to eq("dictation#toggle")
    expect(mic["data-dictation-target"]).to eq("button")
    help = rendered.at_css(".phrase-band__help")
    expect(help.has_attribute?("hidden")).to be(false)
    expect(help["data-phrase-fill-target"]).to eq("help")
    status = rendered.at_css(".phrase-band__status")
    expect(status.has_attribute?("hidden")).to be(true)
    expect(status["aria-live"]).to eq("polite")
  end

  context "with a phrase already typed" do
    let(:text) { "35k groceries yesterday" }

    it "keeps the value and hides the help" do
      expect(input["value"]).to eq("35k groceries yesterday")
      expect(rendered.at_css(".phrase-band__help").has_attribute?("hidden")).to be(true)
    end
  end

  { account: "e.g. 35k groceries yesterday", person: "e.g. she paid me back 20k", goal: "e.g. 25k from MTN" }.each do |key, placeholder|
    context "opened from a #{key}" do
      let(:phrase_context_key) { key }

      it "shows the matching example" do
        expect(input["placeholder"]).to eq(placeholder)
      end
    end
  end

  context "in French" do
    around { |example| I18n.with_locale(:fr) { example.run } }

    it "dictates in French" do
      expect(rendered.at_css(".phrase-band__field")["data-dictation-lang-value"]).to eq("fr-FR")
    end
  end

  context "inside the native app" do
    before { allow(vc_test_controller).to receive(:turbo_native_app?).and_return(true) }

    it "drops the mic button" do
      expect(rendered.at_css(".phrase-band__mic")).to be_nil
    end
  end
end
