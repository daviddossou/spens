# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin corrections review", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin) { create(:user, :admin) }
  before { sign_in admin, scope: :user }

  def edited_attempt(attrs = {})
    create(:quick_entry_attempt, {
      text: "achat de punaise 7.59",
      locale: "fr",
      outcome: "edited",
      corrections: { "transaction_type_name" => { "from" => "Courses", "to" => "Réparations" } }
    }.merge(attrs))
  end

  describe "GET /admin/corrections" do
    it "lists edited attempts awaiting review" do
      attempt = edited_attempt
      create(:quick_entry_attempt, outcome: "kept") # not listed

      get admin_corrections_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(attempt.text)
    end

    it "hides already-reviewed attempts from the pending tab" do
      edited_attempt(reviewed_at: Time.current, text: "already handled 123")

      get admin_corrections_path
      expect(response.body).not_to include("already handled 123")

      get admin_corrections_path(state: "reviewed")
      expect(response.body).to include("already handled 123")
    end

    it "is blocked for non-admins" do
      sign_in create(:user), scope: :user
      get admin_corrections_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /admin/corrections/:id/teach" do
    it "creates an active alias, marks the attempt reviewed, and writes an audit row" do
      attempt = edited_attempt

      expect {
        post teach_admin_correction_path(id: attempt.id), params: { phrase: "punaise", taxonomy_key: "home_repairs" }
      }.to change(LearnedAlias, :count).by(1).and change(AdminAuditLog, :count).by(1)

      row = LearnedAlias.last
      expect(row).to be_active
      expect(row.taxonomy_key).to eq("home_repairs")
      expect(attempt.reload.reviewed_at).to be_present
      expect(AdminAuditLog.last.action).to eq("teach_correction")
    end

    it "creates an active kind keyword when a kind is chosen" do
      attempt = edited_attempt

      post teach_admin_correction_path(id: attempt.id), params: { phrase: "approvisionnement", kind: "transfer" }

      expect(LearnedKeyword.last).to have_attributes(phrase: "approvisionnement", kind: "transfer", state: "active")
      expect(attempt.reload.reviewed_at).to be_present
    end

    it "rejects an empty submission without marking the attempt reviewed" do
      attempt = edited_attempt

      post teach_admin_correction_path(id: attempt.id), params: { phrase: "" }

      expect(attempt.reload.reviewed_at).to be_nil
      expect(flash[:alert]).to be_present
    end
  end

  describe "PATCH /admin/corrections/:id/dismiss" do
    it "marks the attempt reviewed" do
      attempt = edited_attempt

      expect { patch dismiss_admin_correction_path(id: attempt.id) }
        .to change { attempt.reload.reviewed_at }.from(nil)
    end
  end
end
