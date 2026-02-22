# frozen_string_literal: true

require "rails_helper"

RSpec.describe LocaleHelper, type: :helper do
  describe "#url_with_locale" do
    context "when locale is default" do
      before { I18n.default_locale = :en }

      it "returns path without locale prefix" do
        expect(helper.url_with_locale("/dashboard", :en)).to eq("/dashboard")
      end
    end

    context "when locale is not default" do
      before { I18n.default_locale = :en }

      it "returns path with locale prefix" do
        expect(helper.url_with_locale("/dashboard", :fr)).to eq("/fr/dashboard")
      end
    end

    context "when locale is not specified" do
      before do
        I18n.default_locale = :en
        I18n.locale = :fr
      end

      it "uses current locale" do
        expect(helper.url_with_locale("/dashboard")).to eq("/fr/dashboard")
      end
    end
  end

  describe "#language_links" do
    before do
      I18n.available_locales = [:en, :fr]
      I18n.locale = :en
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(controller: "home", action: "index"))
    end

    it "generates links for all available locales" do
      result = helper.language_links
      expect(result).to include("EN")
      expect(result).to include("FR")
    end

    it "wraps links in a div" do
      result = helper.language_links
      expect(result).to include("<div")
      expect(result).to include("flex space-x-2")
    end

    it "applies active class to current locale" do
      result = helper.language_links
      expect(result).to include("bg-primary text-white")
    end
  end
end
