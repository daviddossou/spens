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
end
