# frozen_string_literal: true

require "rails_helper"

RSpec.describe CohortsController, type: :request do
  before { allow(Rails.application.config.x).to receive(:canonical_origin).and_return("https://spens.me") }

  let(:html) { Nokogiri::HTML(response.body) }
  let(:group) { "https://chat.whatsapp.com/ABC" }

  describe "GET /cohorte" do
    it "offers the active cohort's group while registrations are open" do
      create(:cohort, campaign: "cohorte-nov", whatsapp_group_url: group)

      get "/cohorte?utm_source=facebook"

      expect(response).to have_http_status(:ok)
      expect(html.at_css("html")["data-cohort"]).to eq("open")
      expect(html.css('a[data-track="join"]').map { |a| a["href"] }).to eq([ group, group ])
      expect(html.css('a[data-track="waitlist"]').map { |a| a["href"] }).to all(start_with("https://wa.me/33689138559?text="))
      expect(html.css(".translation_missing")).to be_empty
    end

    it "switches to the full state once registrations are closed, or without a group" do
      create(:cohort, registrations_closed: true)
      get "/cohorte"
      expect(html.at_css("html")["data-cohort"]).to eq("full")

      Cohort.delete_all
      get "/cohorte"
      expect(html.at_css("html")["data-cohort"]).to eq("full")
    end

    it "previews the full state with ?etat=complet" do
      create(:cohort)

      get "/cohorte?etat=complet"

      expect(html.at_css("html")["data-cohort"]).to eq("full")
      expect(html.at_css('script[type="application/ld+json"]').text).to include("SoldOut")
    end

    it "is indexable, French, canonical on one URL and shares its own image" do
      create(:cohort)

      get "/en/cohorte"

      expect(response.headers["X-Robots-Tag"]).to be_nil
      expect(html.at_css("html")["lang"]).to eq("fr")
      expect(html.at_css('link[rel="canonical"]')["href"]).to eq("https://spens.me/cohorte")
      expect(html.at_css('meta[property="og:url"]')["content"]).to eq("https://spens.me/cohorte")
      expect(html.at_css('meta[property="og:image"]')["content"]).to eq("https://spens.me/og-cohorte.png")
      expect(Rails.public_path.join("og-cohorte.png")).to exist
      expect(JSON.parse(html.at_css('script[type="application/ld+json"]').text)).to include("@type" => "Event", "startDate" => "2026-11-01")
    end

    it "issues the dedup ids the click beacon will redeem" do
      create(:cohort)

      get "/cohorte"

      ids = session[:meta_event_ids]
      expect(ids.keys).to include("page_view", "cohort_join", "cohort_waitlist")
      expect(response.body).to include(ids["cohort_join"])
    end
  end

  describe "POST /meta/events for the cohort page" do
    it "doubles the join click server-side with its placement" do
      create(:cohort)
      allow(Meta).to receive(:send_event_later)
      cookies[:mkt_consent] = "granted"
      get "/cohorte"
      event_id = session[:meta_event_ids]["cohort_join"]

      post "/meta/events", params: { event: "cohort_join", placement: "bottom" }, as: :json

      expect(response).to have_http_status(:no_content)
      expect(Meta).to have_received(:send_event_later).with(hash_including(event_name: "spens_cohorte_join", event_id: event_id, custom_data: { content_name: "bottom" }))
    end
  end
end
