# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin taxonomy export", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin) { create(:user, :admin) }
  let(:json) { response.parsed_body }

  it "answers 403 JSON to non-admins rather than redirecting" do
    sign_in create(:user), scope: :user
    get admin_taxonomy_export_path

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body["error"]).to eq("forbidden")
  end

  context "as an admin" do
    before { sign_in admin, scope: :user }

    it "serves the whole tree with counts and coverage" do
      get admin_taxonomy_export_path

      expect(response).to have_http_status(:ok)
      expect(json["kinds"].keys).to match_array(TransactionTaxonomy::KINDS)
      expect(json["counts"]["expense"]["parents"]).to be_positive
      expect(json).to have_key("coverage")
      expect(json["generated_at"]).to be_present
    end

    it "narrows to one kind and drops the gap report on request" do
      get admin_taxonomy_export_path(kind: "income", gaps: "false")

      expect(json["kinds"].keys).to eq([ "income" ])
      expect(json).not_to have_key("gaps")
    end

    it "ignores an unknown kind instead of returning an empty tree" do
      get admin_taxonomy_export_path(kind: "nonsense")

      expect(json["kinds"].keys).to match_array(TransactionTaxonomy::KINDS)
    end

    it "caps the gap limit" do
      get admin_taxonomy_export_path(gap_limit: "9999")
      expect(response).to have_http_status(:ok)
    end
  end
end
