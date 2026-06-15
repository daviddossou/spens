# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin access", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin) { create(:user, :admin) }
  let(:user)  { create(:user) }

  it "sends an unauthenticated visitor to sign in" do
    get admin_root_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "redirects a signed-in non-admin back to the app" do
    sign_in user, scope: :user
    get admin_root_path
    expect(response).to redirect_to(root_path)
  end

  it "lets an admin in" do
    sign_in admin, scope: :user
    get admin_root_path
    expect(response).to have_http_status(:success)
  end

  it "keeps every admin section behind the gate for non-admins" do
    sign_in user, scope: :user
    [ admin_users_path, admin_spaces_path, admin_transactions_path,
      admin_quick_entry_attempts_path, admin_audit_logs_path,
      admin_learned_aliases_path, admin_learned_keywords_path ].each do |path|
      get path
      expect(response).to redirect_to(root_path), "expected #{path} to be gated"
    end
  end
end
