# frozen_string_literal: true

module Spaces
  # @label Pending invitation
  class InvitationComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # An invitation sent last week, not yet accepted
    def default
      invitation = Invitation.new(email: "marie@example.com", created_at: 1.week.ago, space: preview_space)
      render with_helpers(Spaces::InvitationComponent.new(invitation: invitation))
    end
  end
end
