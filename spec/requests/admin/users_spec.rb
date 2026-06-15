# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin users", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin)  { create(:user, :admin) }
  let(:target) { create(:user) }

  before { sign_in admin }

  it "grants admin and logs it" do
    expect { patch grant_admin_admin_user_path(id: target.id) }
      .to change { target.reload.admin? }.from(false).to(true)
      .and change(AdminAuditLog, :count).by(1)

    expect(AdminAuditLog.last.action).to eq("grant_admin")
  end

  it "revokes admin from another admin" do
    other = create(:user, :admin)

    patch revoke_admin_admin_user_path(id: other.id)
    expect(other.reload.admin?).to be(false)
    expect(AdminAuditLog.last.action).to eq("revoke_admin")
  end

  it "refuses to revoke your own admin" do
    patch revoke_admin_admin_user_path(id: admin.id)
    expect(admin.reload.admin?).to be(true)
  end

  it "filters the user list by email" do
    create(:user, email: "needle@example.com")
    get admin_users_path(q: "needle")
    expect(response.body).to include("needle@example.com")
  end
end
