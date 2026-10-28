# frozen_string_literal: true

require "rails_helper"

RSpec.describe CohortLinksController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:browser) { { "User-Agent" => "Mozilla/5.0 (Linux; Android 14) Chrome/130.0 Mobile Safari/537.36" } }
  let(:utm) { { utm_source: "whatsapp", utm_medium: "groupe", utm_campaign: "cohorte-nov" } }

  before { create(:cohort, campaign: "cohorte-nov", whatsapp_group_url: "https://chat.whatsapp.com/ABC") }

  describe "GET /c/:code" do
    it "sends a signed-out visitor to sign-in with the UTMs, remembering the screen" do
      get "/c/1", headers: browser

      expect(response).to redirect_to(new_user_session_path(**utm, utm_content: "1"))
      expect(session[:return_path]).to include("path" => "/accounts/new")
    end

    it "sends a signed-in member straight to the screen with the UTMs" do
      sign_in create(:user), scope: :user

      get "/c/9", headers: browser

      expect(response).to redirect_to(new_transaction_path(kind: "transfer", **utm, utm_content: "9"))
      expect(session[:return_path]).to be_nil
    end

    it "sends the welcome codes to sign-up" do
      get "/c/a", headers: browser

      expect(response).to redirect_to(new_user_registration_path(**utm, utm_content: "a"))
    end

    it "sends the simulation to the landing's calculator, signed in or not" do
      get "/c/sim", headers: browser
      expect(response).to redirect_to(landing_path(section: "calculator", **utm, utm_content: "sim", anchor: "calculator"))
      expect(session[:return_path]).to be_nil

      sign_in create(:user), scope: :user
      get "/c/sim", headers: browser
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="calculator"')
    end

    it "lands on the remembered screen after signing in" do
      user = create(:user)
      get "/c/7", headers: browser
      post user_session_path, params: { email: user.email }
      post auth_verification_path, params: { otp_code: user.reload.otp_code }

      expect(response).to redirect_to(new_goal_path)
      expect(session[:return_path]).to be_nil
    end

    it "lands on the remembered screen once a newcomer finishes onboarding" do
      get "/c/1", headers: browser
      post user_registration_path, params: { user: { first_name: "Awa", email: "awa@example.com" } }
      expect(response).to redirect_to(onboarding_path)

      patch onboarding_summaries_path

      expect(response).to redirect_to(new_account_path)
    end

    it "forgets a screen remembered more than a day ago" do
      user = create(:user)
      get "/c/7", headers: browser
      travel 2.days do
        post user_session_path, params: { email: user.email }
        post auth_verification_path, params: { otp_code: user.reload.otp_code }
      end

      expect(response).to redirect_to(dashboard_path)
    end

    it "logs the click with its context" do
      user = create(:user)
      sign_in user, scope: :user

      expect {
        get "/c/3", headers: browser.merge("Referer" => "https://web.whatsapp.com/")
      }.to change(ShortLinkClick, :count).by(1)

      click = ShortLinkClick.last
      expect(click).to have_attributes(code: "3", campaign: "cohorte-nov", user: user,
                                       referer: "https://web.whatsapp.com/", user_agent: browser["User-Agent"])
    end

    it "serves a generic Open Graph preview to link fetchers without counting a click" do
      allow(Analytics).to receive(:track_anonymous)

      expect {
        get "/c/4", headers: { "User-Agent" => "WhatsApp/2.23.20 A" }
      }.not_to change(ShortLinkClick, :count)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('property="og:title" content="Spens"', "og-fr.png")
      expect(Analytics).not_to have_received(:track_anonymous)
    end

    it "sends join to the active cohort's group" do
      get "/c/join", headers: browser

      expect(response).to redirect_to("https://chat.whatsapp.com/ABC")
      expect(ShortLinkClick.last.code).to eq("join")
    end

    it "falls back to the home when no cohort is active" do
      Cohort.update_all(active: false)

      get "/c/join", headers: browser
      expect(response).to redirect_to(root_path)

      get "/c/1", headers: browser
      expect(response).to redirect_to(new_user_session_path(utm_source: "whatsapp", utm_medium: "groupe",
                                                            utm_campaign: "cohorte", utm_content: "1"))
    end

    it "falls back to the home for an unknown code" do
      get "/c/nope", headers: browser

      expect(response).to redirect_to(root_path)
      expect(ShortLinkClick.count).to eq(0)
    end
  end
end
