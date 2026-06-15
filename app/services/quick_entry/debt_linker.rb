# frozen_string_literal: true

module QuickEntry
  # When the utterance names someone with an ongoing debt, link it — but auto-create ONLY when
  # the direction is clear (received/repaid → debt_in; a lent/borrowed keyword → that kind). A
  # bare mention with no direction ("2000 Julius") is ambiguous (did you lend more, or were you
  # repaid?), so we prefill the debt form and let the user choose rather than guess.
  class DebtLinker
    DEBT_KINDS = %w[debt_in debt_out].freeze
    DIRECTION_KIND = { "lent" => "debt_out", "borrowed" => "debt_in" }.freeze

    def self.link(draft, text:, space:)
      new(draft, text: text, space: space).link
    end

    def initialize(draft, text:, space:)
      @draft = draft
      @text = text
      @space = space
    end

    def link
      return @draft if @draft.amount.blank?

      debt = matching_debt or return @draft

      case @draft.kind
      when "income"    then auto_linked(debt, "debt_in")  # received from them → repaid, direction clear
      when *DEBT_KINDS then auto_linked(debt, @draft.kind) # a debt keyword set the direction
      when "expense"   then expense_debt(debt)            # bare mention → ambiguous direction
      else @draft
      end
    end

    private

    # A clear category means it's a real categorised expense, not a debt with this person.
    def expense_debt(debt)
      @draft.transaction_type_name.present? ? @draft : prefill_form(debt)
    end

    # Direction is clear → link the existing debt and let it auto-create.
    def auto_linked(debt, kind)
      @draft.with(kind: kind, transaction_type_name: nil, debt_id: debt.id, unresolved: [])
    end

    # Direction is unknown → open the debt form, person + a default direction prefilled, no
    # debt_id so it can't auto-create.
    def prefill_form(debt)
      @draft.with(
        kind: DIRECTION_KIND.fetch(debt.direction, "debt_out"),
        transaction_type_name: nil,
        contact_name: debt.name,
        direction: debt.direction,
        unresolved: [ :direction ]
      )
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
