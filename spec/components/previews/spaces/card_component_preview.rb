# frozen_string_literal: true

module Spaces
  # @label Space card
  class CardComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # Another space, with its switch action
    def default
      space = Space.new(id: SecureRandom.uuid, name: "Family", currency: "XOF", country: "BJ")
      render with_helpers(Spaces::CardComponent.new(space: space, active: false))
    end

    # The space currently in use
    def active
      render with_helpers(Spaces::CardComponent.new(space: preview_space, active: true))
    end

    # A space with no currency or country set yet
    def bare
      space = Space.new(id: SecureRandom.uuid, name: "Side project")
      render with_helpers(Spaces::CardComponent.new(space: space, active: false))
    end
  end
end
