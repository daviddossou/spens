# frozen_string_literal: true

require "rails_helper"

# The test cache is a null store, so the counter itself is Rails' concern; these
# cover the "over the limit" answer of each endpoint.
RSpec.describe "Auth rate limits", type: :request do
  let(:user) { create(:user) }

  before { allow(Rails.cache).to receive(:increment).and_return(1_000) }

  it "answers 429 with the form on sign-up" do
    expect { post user_registration_path, params: { user: { first_name: "Jane", email: "jane@example.com" } } }
      .not_to change(User, :count)
    expect(response).to have_http_status(:too_many_requests)
    expect(response.body).to include(I18n.t("auth.rate_limited")).and include("Jane")
  end

  it "answers 429 without sending an OTP on sign-in" do
    post user_session_path, params: { email: user.email }
    expect(response).to have_http_status(:too_many_requests)
    expect(user.reload.otp_code).to be_nil
  end

  context "with a pending OTP session" do
    before do
      allow(Rails.cache).to receive(:increment).and_call_original
      post user_session_path, params: { email: user.email }
      allow(Rails.cache).to receive(:increment).and_return(1_000)
    end

    it "answers 429 on code verification" do
      post auth_verification_path, params: { otp_code: "000000" }
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include(I18n.t("auth.rate_limited"))
    end

    it "answers 429 on resend without a new code" do
      code = user.reload.otp_code
      post resend_otp_path
      expect(response).to have_http_status(:too_many_requests)
      expect(user.reload.otp_code).to eq(code)
    end
  end

  it "answers a bare 429 on meta event beacons" do
    post meta_events_path, params: { event: "view_content" }
    expect(response).to have_http_status(:too_many_requests)
  end
end
