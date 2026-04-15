# frozen_string_literal: true

class InvitationsController < ApplicationController
  def show
    @invitation = Invitation.pending.find_by!(token: params[:token])
    user = User.find_by("LOWER(email) = ?", @invitation.email.downcase)

    if user
      @invitation.accept!(user)
      sign_in(user)
      set_current_space(@invitation.space)
      redirect_to dashboard_path, notice: t(".success")
    else
      session[:pending_invitation_token] = @invitation.token
      redirect_to new_user_registration_path(email: @invitation.email)
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t(".invalid_or_expired")
  end
end
