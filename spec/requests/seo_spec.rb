# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SEO metadata", type: :request do
  include Devise::Test::IntegrationHelpers

  before { allow(Rails.application.config.x).to receive(:canonical_origin).and_return("https://spens.me") }

  def head
    Nokogiri::HTML(response.body).at_css("head")
  end

  def meta(key)
    head.at_css(%(meta[property="#{key}"], meta[name="#{key}"]))&.[]("content")
  end

  describe "indexable public pages" do
    %w[welcome guide privacy terms].each do |page|
      it "lets /#{page} be indexed, with a canonical and language alternates" do
        get "/fr/#{page}?utm_source=guide"

        expect(response.headers["X-Robots-Tag"]).to be_nil
        expect(meta("robots")).to be_nil
        expect(head.at_css('link[rel="canonical"]')["href"]).to eq("https://spens.me/fr/#{page}")
        alternates = head.css('link[rel="alternate"][hreflang]').to_h { |l| [ l["hreflang"], l["href"] ] }
        expect(alternates).to eq(
          "en" => "https://spens.me/en/#{page}", "fr" => "https://spens.me/fr/#{page}",
          "x-default" => "https://spens.me/#{page}"
        )
      end
    end

    it "describes the landing for search and link previews in the page's language" do
      get "/fr/welcome"

      expect(Nokogiri::HTML(response.body).at_css("html")["lang"]).to eq("fr")
      expect(meta("description")).to eq(I18n.t("landing.meta.description", locale: :fr))
      expect(meta("og:title")).to eq(I18n.t("landing.meta.title", locale: :fr))
      expect(meta("og:url")).to eq("https://spens.me/fr/welcome")
      expect(meta("og:locale")).to eq("fr_FR")
      expect(meta("og:image")).to eq("https://spens.me/og-fr.png")
      expect(meta("twitter:card")).to eq("summary_large_image")
      expect(JSON.parse(head.at_css('script[type="application/ld+json"]').text)).to include("@type" => "SoftwareApplication")
    end

    it "ships the share image of every locale" do
      I18n.available_locales.each { |locale| expect(Rails.public_path.join("og-#{locale}.png")).to exist }
    end
  end

  describe "pages kept out of search engines" do
    %w[/en/sign_in /en/sign_up /fr/guide/thanks].each do |path|
      it "marks #{path} noindex" do
        get path

        expect(response.headers["X-Robots-Tag"]).to eq("noindex")
        expect(meta("robots")).to eq("noindex")
        expect(head.at_css('link[rel="canonical"]')).to be_nil
      end
    end

    it "marks the signed-in app noindex" do
      sign_in create(:user), scope: :user
      get "/dashboard"

      expect(response.headers["X-Robots-Tag"]).to eq("noindex")
      expect(meta("robots")).to eq("noindex")
    end
  end

  describe "GET /sitemap.xml" do
    it "lists every indexable page in every language" do
      get "/sitemap.xml"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/xml")
      locs = Nokogiri::XML(response.body).remove_namespaces!.xpath("//loc").map(&:text)
      expect(locs).to match_array(
        %w[welcome guide privacy terms].product(%w[en fr]).map { |page, locale| "https://spens.me/#{locale}/#{page}" }
      )
    end
  end
end
