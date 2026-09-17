# frozen_string_literal: true

module Spaces
  # @label Member card
  class MemberComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # The space owner, with a full name
    def default
      render with_helpers(Spaces::MemberComponent.new(space: preview_space, member: preview_user, full_name: "Awa Diop"))
    end

    # A member who has not filled in a name
    def email_only
      member = User.new(id: SecureRandom.uuid, email: "kofi@example.com")
      render with_helpers(Spaces::MemberComponent.new(space: preview_space, member: member, full_name: ""))
    end
  end
end
