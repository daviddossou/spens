# frozen_string_literal: true

module Admin
  class AuditLogsController < BaseController
    def index
      @logs = paginate(AdminAuditLog.includes(:admin_user).recent)
    end
  end
end
