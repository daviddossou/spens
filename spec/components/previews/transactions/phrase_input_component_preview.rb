# frozen_string_literal: true

module Transactions
  # @label Phrase input
  class PhraseInputComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # Empty, opened from the dashboard
    def default
      render with_helpers(Transactions::PhraseInputComponent.new(text: "", phrase_context_key: :none))
    end

    # A phrase already typed: the help line is hidden
    def filled
      render with_helpers(Transactions::PhraseInputComponent.new(text: "35k groceries yesterday", phrase_context_key: :none))
    end

    # Opened from an account
    def from_account
      render with_helpers(Transactions::PhraseInputComponent.new(text: "", phrase_context_key: :account))
    end

    # Opened from a person's debt page
    def from_person
      render with_helpers(Transactions::PhraseInputComponent.new(text: "", phrase_context_key: :person))
    end

    # Opened from a goal
    def from_goal
      render with_helpers(Transactions::PhraseInputComponent.new(text: "", phrase_context_key: :goal))
    end
  end
end
