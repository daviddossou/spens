# frozen_string_literal: true

# Lets an admin "sign in as" another user and switch back. The real admin's id is stashed in
# the session so the banner (shown app-wide) and the stop action can restore it. Included in
# ApplicationController so `impersonating?` / `true_admin` are available in every view, and the
# stop action works even though `current_user` is the impersonated (non-admin) user.
module Impersonation
  extend ActiveSupport::Concern

  included do
    helper_method :impersonating?, :true_admin
  end

  def impersonating?
    session[:true_admin_user_id].present?
  end

  def true_admin
    return nil unless impersonating?

    @true_admin ||= User.find_by(id: session[:true_admin_user_id])
  end

  private

  # Become `user`, remembering the real admin the first time so nested calls don't lose it.
  def impersonate!(user)
    session[:true_admin_user_id] ||= current_user.id
    sign_in(user)
  end

  # Switch back to the real admin and clear the impersonation. Returns that admin (or nil).
  def stop_impersonating!
    admin = true_admin
    session.delete(:true_admin_user_id)
    sign_in(admin) if admin
    admin
  end
end
