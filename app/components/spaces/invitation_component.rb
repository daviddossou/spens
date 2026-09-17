# frozen_string_literal: true

class Spaces::InvitationComponent < ViewComponent::Base
  def initialize(invitation:)
    @invitation = invitation
  end

  private

  attr_reader :invitation
end
