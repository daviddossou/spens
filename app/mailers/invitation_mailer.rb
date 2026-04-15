# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @space = invitation.space
    @invited_by = invitation.invited_by
    @accept_url = accept_invitation_url(token: invitation.token)

    mail(to: invitation.email, subject: t("invitations.mailer.subject", inviter_name: "#{@invited_by.first_name} #{@invited_by.last_name}", space_name: @space.name))
  end
end
