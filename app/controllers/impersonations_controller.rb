# frozen_string_literal: true

# Ends an impersonation and restores the real admin. Deliberately NOT under Admin:: — mid-
# impersonation current_user is the (non-admin) target, so it must not sit behind the admin gate;
# it's guarded instead by the true-admin id stashed in the session (see Impersonation).
class ImpersonationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_impersonating

  def destroy
    impersonated = current_user
    admin = stop_impersonating!
    if admin
      AdminAuditLog.record_action(admin_user: admin, action: "impersonate_stop", target: impersonated)
      redirect_to admin_root_path, notice: t("admin.impersonation.stopped", name: impersonated.email)
    else
      redirect_to root_path
    end
  end

  private

  def require_impersonating
    redirect_to root_path unless impersonating?
  end
end
