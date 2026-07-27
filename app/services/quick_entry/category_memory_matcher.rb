# frozen_string_literal: true

module QuickEntry
  # Recalls the closest CategoryMemory for a new text: cleans it down to significant tokens
  # (PhraseExtractor), then scores every memory of the space by weighted token overlap —
  # rare tokens count more than ones appearing across many memories, so a single banal
  # shared word can't misfire. Suggestion-only fallback: CategoryInference consults it when
  # no exact alias/taxonomy match fired.
  class CategoryMemoryMatcher
    MIN_SHARED = 2            # shared tokens required...
    DISTINCTIVE_LENGTH = 4    # ...unless one shared token is unique to a memory and this long
    MIN_SCORE = 0.34          # at least ~a third of the memory's weight must be covered

    def self.match(text, space:, locale: I18n.locale)
      new(text, space: space, locale: locale).match
    end

    def initialize(text, space:, locale:)
      @text = text.to_s
      @space = space
      @locale = locale
    end

    def match
      return nil if @space.nil? || memories.empty?
      return nil if query.empty?

      best = memories.filter_map { |memory| scored(memory) }
                     .max_by { |score, memory| [ score, memory.confirmations, memory.updated_at.to_i ] }
      best&.last&.taxonomy_key
    end

    private

    def memories
      @memories ||= CategoryMemory.where(space: @space).to_a
    end

    def query
      @query ||= PhraseExtractor.significant_tokens(text: @text, locale: @locale, space: @space)
                                .map { |t| CategoryText.normalize(t) }.reject(&:blank?).to_set
    end

    # How many memories each token appears in — the rarer, the more it identifies one.
    def document_frequency
      @document_frequency ||= memories.each_with_object(Hash.new(0)) do |memory, df|
        memory.tokens.each { |t| df[t] += 1 }
      end
    end

    def scored(memory)
      shared = memory.tokens.select { |t| query.include?(t) }
      return nil if shared.empty?

      distinctive = shared.any? { |t| document_frequency[t] == 1 && t.length >= DISTINCTIVE_LENGTH }
      return nil unless shared.size >= MIN_SHARED || distinctive

      weight = ->(t) { 1.0 / document_frequency[t] }
      score = shared.sum(&weight) / memory.tokens.sum(&weight)
      score >= MIN_SCORE || distinctive ? [ score, memory ] : nil
    end
  end
end
