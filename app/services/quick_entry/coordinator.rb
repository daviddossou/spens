# frozen_string_literal: true

module QuickEntry
  # Entry point for the pipeline: parse the utterance, then link it to a known debt if one is
  # named. An LLM fallback for low-confidence cases lands in a later phase.
  class Coordinator
    def self.call(text, space:, locale: I18n.locale)
      new(text, space: space, locale: locale).call
    end

    def initialize(text, space:, locale: I18n.locale)
      @text = text
      @space = space
      @locale = locale
    end

    def call
      draft = Parser.parse(@text, space: @space, locale: @locale)
      DebtLinker.link(draft, text: @text, space: @space)
    end
  end
end
