# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show impersonate grant_admin revoke_admin]

    def index
      scope = User.includes(:memberships).order(created_at: :desc)
      scope = scope.where("email ILIKE ?", "%#{params[:q]}%") if params[:q].present?
      @users = paginate(scope)
    end

    def show
      @owned_spaces = @user.owned_spaces
      @spaces = @user.spaces.includes(:accounts)
      @recent_transactions = @user.transactions.includes(:transaction_type, :account, :space)
                                  .order(transaction_date: :desc, created_at: :desc).limit(10)
      @debts = @user.debts.order(created_at: :desc).limit(10)
      @attempts = QuickEntryAttempt.where(user: @user).order(created_at: :desc).limit(10)
    end

    # Become this user. Refused for admin targets (an admin must never silently wear another
    # admin's hat). The real admin is restored from the banner's "stop" button.
    def impersonate
      if @user.admin?
        redirect_to admin_user_path(id: @user.id), alert: t("admin.impersonation.refused_admin")
      else
        impersonate!(@user)
        record_admin_action("impersonate_start", target: @user)
        redirect_to root_path, notice: t("admin.impersonation.started", name: @user.email)
      end
    end

    def grant_admin
      @user.update!(admin: true)
      record_admin_action("grant_admin", target: @user)
      redirect_to admin_user_path(id: @user.id), notice: t("admin.users.granted")
    end

    def revoke_admin
      if @user == current_user
        redirect_to admin_user_path(id: @user.id), alert: t("admin.users.cannot_revoke_self")
      else
        @user.update!(admin: false)
        record_admin_action("revoke_admin", target: @user)
        redirect_to admin_user_path(id: @user.id), notice: t("admin.users.revoked")
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
