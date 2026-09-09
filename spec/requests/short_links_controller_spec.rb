# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShortLinksController, type: :request do
  describe "GET /g/:code" do
    it "redirects the cover QR to the landing with campaign params" do
      get "/g/c"

      expect(response).to redirect_to(
        root_path(utm_source: "guide", utm_medium: "pdf", utm_campaign: "guide-septembre",
                  utm_content: "couverture", guide_link: "couverture")
      )
    end

    it "redirects chapter links to their app screen with their guide_link" do
      get "/g/ch1"

      expect(response.headers["Location"]).to include("/accounts", "guide_link=action-ch1")
    end

    it "falls back to the landing for an unknown code" do
      get "/g/nope"

      expect(response).to redirect_to(root_path)
    end

    it "captures the guide_link as first touch when following the redirect" do
      get "/g/f"
      get URI(response.headers["Location"]).request_uri

      expect(session[:meta_first_touch]).to include("guide_link" => "fin", "utm_content" => "fin")
    end
  end
end
