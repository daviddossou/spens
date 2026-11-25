# frozen_string_literal: true

class Transactions::PhraseInputComponent < ViewComponent::Base
  # statement_import: show the photo button of the statement import (the caller checks access).
  def initialize(text:, phrase_context_key:, statement_import: false)
    @text = text
    @phrase_context_key = phrase_context_key
    @statement_import = statement_import
  end

  private

  attr_reader :text, :phrase_context_key

  delegate :turbo_native_app?, to: :helpers

  def statement_import?
    @statement_import
  end
end
