# frozen_string_literal: true

module QuickEntry
  # When the utterance names someone with an ongoing debt ("…par Julius"), retarget the draft
  # to a linked debt transaction — income -> debt_in (repaid to you), expense -> debt_out. No
  # match passes through unchanged.
  class DebtLinker
    LINKABLE_KINDS = %w[expense income].freeze

    def self.link(draft, text:, space:)
      new(draft, text: text, space: space).link
    end

    def initialize(draft, text:, space:)
      @draft = draft
      @text = text
      @space = space
    end

    def link
      return @draft unless linkable?

      debt = matching_debt or return @draft

      @draft.with(
        kind: @draft.kind == "income" ? "debt_in" : "debt_out",
        transaction_type_name: nil,
        debt_id: debt.id,
        unresolved: []
      )
    end

    private

    def linkable?
      @draft.amount.present? && LINKABLE_KINDS.include?(@draft.kind)
    end

    # First ongoing debt whose person name appears in the utterance (accent/case-insensitive).
    def matching_debt
      normalized = CategoryText.normalize(@text)
      @space.debts.ongoing.find do |debt|
        name = CategoryText.normalize(debt.name)
        name.length >= 2 && normalized.include?(name)
      end
    end
  end
end
