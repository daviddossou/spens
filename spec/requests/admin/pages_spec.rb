# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin pages render", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin) { create(:user, :admin) }
  let(:other) { create(:user) }
  let(:space) { admin.spaces.first }

  before do
    sign_in admin
    LearnedAlias.teach(phrase: "zoomzoom", taxonomy_key: "moto_taxi", source: "ai")
    LearnedKeyword.teach(phrase: "depanne", kind: "debt_out", source: "ai")
    create(:quick_entry_attempt, user: other, space: other.spaces.first, text: "2000 zoomzoom")
  end

  it "renders the dashboard with metrics" do
    get admin_root_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include(I18n.t("admin.dashboard.title"))
  end

  it "renders each list and detail page" do
    [ admin_users_path, admin_user_path(id: other.id), admin_spaces_path, admin_space_path(id: space.id),
      admin_transactions_path, admin_quick_entry_attempts_path, admin_audit_logs_path,
      admin_learned_aliases_path, admin_learned_keywords_path ].each do |path|
      get path
      expect(response).to have_http_status(:success), "expected #{path} to render"
    end
  end

  it "shows a candidate's phrase on the review queue with a sample utterance" do
    get admin_learned_aliases_path
    expect(response.body).to include("zoomzoom")
    expect(response.body).to include("2000 zoomzoom") # best-effort sample utterance
  end
end
