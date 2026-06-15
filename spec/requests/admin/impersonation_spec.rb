# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin impersonation", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin)  { create(:user, :admin) }
  let(:target) { create(:user) }

  before { sign_in admin, scope: :user }

  it "starts impersonating a regular user and logs it" do
    expect { post impersonate_admin_user_path(id: target.id) }
      .to change(AdminAuditLog, :count).by(1)

    expect(response).to redirect_to(root_path)
    expect(AdminAuditLog.last).to have_attributes(action: "impersonate_start", admin_user_id: admin.id, target_id: target.id)
  end

  it "shows the banner and blocks the admin area while impersonating" do
    post impersonate_admin_user_path(id: target.id)

    get dashboard_path
    expect(response.body).to include("impersonation-banner")

    get admin_root_path # current_user is now the non-admin target
    expect(response).to redirect_to(root_path)
  end

  it "refuses to impersonate another admin" do
    other_admin = create(:user, :admin)

    expect { post impersonate_admin_user_path(id: other_admin.id) }.not_to change(AdminAuditLog, :count)
    expect(response).to redirect_to(admin_user_path(id: other_admin.id))
  end

  it "stops impersonating, restores the admin, and logs it" do
    post impersonate_admin_user_path(id: target.id)

    expect { delete stop_impersonating_path }
      .to change { AdminAuditLog.where(action: "impersonate_stop").count }.by(1)
    expect(response).to redirect_to(admin_root_path)

    # the real admin is back: the admin area is reachable again
    get admin_root_path
    expect(response).to have_http_status(:success)
  end

  it "ignores a stop request when not impersonating" do
    delete stop_impersonating_path
    expect(response).to redirect_to(root_path)
  end
end
