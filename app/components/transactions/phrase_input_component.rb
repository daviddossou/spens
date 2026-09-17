# frozen_string_literal: true

class Transactions::PhraseInputComponent < ViewComponent::Base
  def initialize(text:, phrase_context_key:)
    @text = text
    @phrase_context_key = phrase_context_key
  end

  private

  attr_reader :text, :phrase_context_key

  delegate :turbo_native_app?, to: :helpers
end
