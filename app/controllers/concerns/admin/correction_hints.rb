# frozen_string_literal: true

module Admin
  # Prefills for the correction teach form, shared by the corrections screen and the
  # dashboard inbox.
  module CorrectionHints
    private

    # { phrase:, taxonomy_key:, kind: } prefills: the extractor's residual phrase, the taxonomy
    # key of the category the user corrected to, and a structural-kind correction when one was
    # recorded. A pending auto-candidate for the phrase fills gaps.
    def hint_for(attempt)
      phrase = QuickEntry::PhraseExtractor.call(text: attempt.text, locale: attempt.locale, space: attempt.space)
      corrections = attempt.corrections || {}

      taxonomy_key = TransactionTaxonomy.key_for_name(corrections.dig("transaction_type_name", "to"))
      taxonomy_key ||= phrase && LearnedAlias.candidate.find_by(phrase: CategoryText.normalize(phrase))&.taxonomy_key

      kind = corrections.dig("kind", "to")
      kind = "transfer" if kind.to_s.start_with?("transfer")
      kind = nil unless LearnedKeyword::KINDS.include?(kind)

      { phrase: phrase, taxonomy_key: taxonomy_key, kind: kind }
    end
  end
end
