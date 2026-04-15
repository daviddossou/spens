# frozen_string_literal: true

class InvitationsController < ApplicationController
  def show
    @invitation = Invitation.pending.find_by!(token: params[:token])
    session[:pending_invitation_token] = @invitation.token
    user = User.find_by("LOWER(email) = ?", @invitation.email.downcase)

    if user
      redirect_to new_user_session_path, notice: t(".sign_in_to_accept")
    else
      redirect_to new_user_registration_path(email: @invitation.email)
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t(".invalid_or_expired")
  end
end
