# frozen_string_literal: true

module QuickEntry
  # Runs the pipeline: rules first (linking a known debt up front so it can auto-create without
  # the LLM); if still not confident AND the LLM is enabled, let it classify the kind and fill
  # the structure the rules couldn't. The uniform `confident?` gate then decides auto-create vs
  # prefilled form — we only auto-create against entities that already exist. Returns the final
  # draft plus the raw AI output (for logging + the AI-assist learner).
  class Coordinator
    Result = Data.define(:draft, :ai_draft)
    DEBT_KINDS = %w[debt_in debt_out].freeze
    DIRECTION_KIND = { "lent" => "debt_out", "borrowed" => "debt_in" }.freeze

    def self.call(text, space:, locale: I18n.locale)
      new(text, space: space, locale: locale).call
    end

    def initialize(text, space:, locale: I18n.locale)
      @text = text
      @space = space
      @locale = locale
    end

    def call
      rules = DebtLinker.link(Parser.parse(@text, space: @space, locale: @locale), text: @text, space: @space)
      return Result.new(draft: rules, ai_draft: nil) if rules.confident? || form_ready?(rules) || !LlmParser.enabled?

      ai = LlmParser.new(space: @space, locale: @locale).parse(@text)
      return Result.new(draft: rules, ai_draft: nil) unless ai

      Result.new(draft: merge(rules, ai), ai_draft: ai_draft(ai))
    end

    private

    # The rules already detected a structural kind and resolved what they could — the rest is a
    # human choice (a new account, the debt direction), so the LLM adds nothing. A debt without a
    # resolved person is the exception: the LLM extracts that person for the form.
    def form_ready?(draft)
      case draft.kind
      when "transfer"  then true
      when *DEBT_KINDS then draft.contact_name.present?
      else false
      end
    end

    # Rules keep precedence when they detected a structural kind; otherwise the AI's kind wins.
    def merge(rules, ai)
      kind = structural?(rules.kind) ? rules.kind : ai.kind

      case kind
      when "transfer"          then transfer_draft(rules, ai)
      when "debt", *DEBT_KINDS then debt_draft(rules, ai, kind)
      else                          backfill(rules, ai)
      end
    end

    def structural?(kind)
      kind == "transfer" || DEBT_KINDS.include?(kind)
    end

    # Expense/income: keep what the rules resolved, let the model fill the gaps.
    def backfill(rules, ai)
      type_name = rules.transaction_type_name.presence || ai.category_name
      kind = rules.transaction_type_name.present? ? rules.kind : (ai.kind.presence || rules.kind)
      amount = rules.amount || ai.amount

      unresolved = []
      unresolved << :amount if amount.blank?
      unresolved << :category if type_name.blank?

      Draft.new(
        kind: kind, amount: amount, account_name: rules.account_name,
        transaction_type_name: type_name, fee_amount: rules.fee_amount,
        transaction_date: rules.transaction_date, description: rules.description,
        unresolved: unresolved
      )
    end

    # Auto-create only when BOTH ends resolve to existing accounts; otherwise prefill the form
    # with whatever did resolve (a new account is created on the user's confirmed submit).
    def transfer_draft(rules, ai)
      from = existing_account(ai.from_account) || rules.from_account_name
      to   = existing_account(ai.to_account) || rules.to_account_name

      unresolved = []
      unresolved << :amount if rules.amount.blank?
      unresolved << :from_account if from.blank?
      unresolved << :to_account if to.blank?

      Draft.new(
        kind: "transfer", amount: rules.amount, from_account_name: from, to_account_name: to,
        fee_amount: rules.fee_amount, transaction_date: rules.transaction_date,
        description: rules.description, unresolved: unresolved
      )
    end

    # A debt with a NEW person (a known one would already be linked by DebtLinker above): prefill
    # the debt form with the person + direction. Not confident (no debt_id) → the form.
    def debt_draft(rules, ai, kind)
      resolved = DEBT_KINDS.include?(kind) ? kind : DIRECTION_KIND.fetch(ai.direction.to_s, "debt_out")

      Draft.new(
        kind: resolved, amount: rules.amount,
        contact_name: rules.contact_name.presence || ai.person,
        direction: rules.direction.presence || (resolved == "debt_in" ? "borrowed" : "lent"),
        transaction_date: rules.transaction_date, description: rules.description,
        unresolved: [ :debt ]
      )
    end

    def existing_account(name)
      return nil if name.blank?

      target = CategoryText.normalize(name)
      return nil if target.length < 2

      @space.accounts.pluck(:name).find do |account|
        normalized = CategoryText.normalize(account)
        normalized.include?(target) || target.include?(normalized)
      end
    end

    def ai_draft(ai)
      {
        "kind" => ai.kind, "amount" => ai.amount,
        "category_key" => ai.category_key, "category_name" => ai.category_name, "phrase" => ai.phrase,
        "from_account" => ai.from_account, "to_account" => ai.to_account,
        "person" => ai.person, "direction" => ai.direction
      }
    end
  end
end
