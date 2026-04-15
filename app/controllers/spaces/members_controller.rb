# frozen_string_literal: true

class Spaces::MembersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_space

  def index
    @members = @space.members.order(:first_name, :last_name)
    @pending_invitations = @space.invitations.pending.order(created_at: :desc)
  end

  def new
  end

  def create
    @invitation = @space.invitations.new(
      email: invitation_params[:email],
      invited_by: current_user
    )

    if @invitation.save
      InvitationMailer.invite(@invitation).deliver_later
      redirect_to space_members_path(space_id: @space.id), notice: t(".success"), status: :see_other
    else
      redirect_to space_members_path(space_id: @space.id), alert: @invitation.errors.full_messages.first, status: :see_other
    end
  end

  private

  def set_space
    @space = current_user.spaces.find(params[:space_id])
  end

  def invitation_params
    params.permit(:email)
  end
end
