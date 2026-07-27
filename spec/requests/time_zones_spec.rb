# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::TimeZonesController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before { sign_in user, scope: :user }

  describe "PATCH /time_zone" do
    it "stores a valid IANA zone" do
      patch time_zone_path, params: { time_zone: "Africa/Porto-Novo" }, as: :json
      expect(response).to have_http_status(:no_content)
      expect(user.reload.time_zone).to eq("Africa/Porto-Novo")
    end

    it "ignores an unknown zone" do
      patch time_zone_path, params: { time_zone: "Not/AZone" }, as: :json
      expect(response).to have_http_status(:no_content)
      expect(user.reload.time_zone).to be_nil
    end
  end
end
