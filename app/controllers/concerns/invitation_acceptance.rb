# frozen_string_literal: true

module InvitationAcceptance
  extend ActiveSupport::Concern

  private

  def accept_pending_invitation(user)
    token = session.delete(:pending_invitation_token)
    return unless token

    invitation = Invitation.pending.find_by(token: token)
    return unless invitation

    invitation.accept!(user)
    Analytics.track(user, "invitation_accepted", space_id: invitation.space_id)
    invitation.space
  end
end
