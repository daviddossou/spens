# frozen_string_literal: true

module Admin
  # Base for the admin area. Gated by the `admin` flag on the user; not space-scoped (admins see
  # everything) and exempt from the onboarding redirect. While impersonating, current_user is the
  # (non-admin) target, so the gate correctly keeps the admin area out of reach until they stop.
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :require_admin!
    skip_before_action :redirect_to_onboarding, raise: false

    private

    def require_admin!
      return if current_user&.admin?

      redirect_to root_path, alert: t("admin.not_authorized")
    end

    # Records a privileged action against the REAL admin (even mid-impersonation, defensively).
    def record_admin_action(action, target: nil, metadata: {})
      AdminAuditLog.record_action(admin_user: true_admin || current_user, action: action,
                                  target: target, metadata: metadata)
    end

    # Simple offset pagination shared by the admin lists (no new gem). Sets @page/@has_more.
    def paginate(scope, per_page: 30)
      @page = [ params[:page].to_i, 1 ].max
      @per_page = per_page
      records = scope.offset((@page - 1) * per_page).limit(per_page + 1).to_a
      @has_more = records.size > per_page
      records.first(per_page)
    end
  end
end
