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
      return Result.new(draft: rules, ai_draft: nil) if rules.confident? || form_ready?(rules) || !ai_parser

      ai = ai_parser.new(space: @space, locale: @locale).parse(@text)
      return Result.new(draft: rules, ai_draft: nil) unless ai

      Result.new(draft: merge(rules, ai), ai_draft: ai_draft(ai))
    end

    private

    # Claude Haiku is the primary decomposer; the OpenAI-compatible path (Ollama) stays as a
    # fallback if only it is configured. nil when neither is enabled → rules-only.
    def ai_parser
      return AnthropicParser if AnthropicParser.enabled?
      return LlmParser if LlmParser.enabled?

      nil
    end

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

    # Expense/income: keep what the rules resolved, let the model fill the gaps, and never
    # leave it uncategorised — fall back to the "Other" default so the entry always lands
    # somewhere (the note keeps the detail; the user can recategorise).
    def backfill(rules, ai)
      kind = rules.transaction_type_name.present? ? rules.kind : (ai.kind.presence || rules.kind)
      type_name = rules.transaction_type_name.presence || ai.category_name.presence || default_category_name(kind)
      amount = rules.amount || ai.amount

      unresolved = []
      unresolved << :amount if amount.blank?

      Draft.new(
        kind: kind, amount: amount, account_name: rules.account_name,
        transaction_type_name: type_name, fee_amount: rules.fee_amount,
        transaction_date: rules.transaction_date, description: rules.description,
        note: raw_note, label: ai.label, unresolved: unresolved
      )
    end

    # The "Other" parent for the kind — the last-resort category so quick add is never blank.
    def default_category_name(kind)
      key = kind == "income" ? "other_income" : "other_expense"
      TransactionTaxonomy.name(key, @locale)
    end

    # note = the raw phrase the user typed, kept verbatim as searchable proof of what
    # was dictated. The short title label is a separate output (ai.label).
    def raw_note
      @text.to_s.strip.presence
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
        description: rules.description, note: raw_note, unresolved: unresolved
      )
    end

    # A debt with a NEW person (a known one would already be linked by DebtLinker above). With a
    # clear direction and a resolved person + amount it auto-creates the counterparty on submit;
    # only a missing person/amount falls back to the prefilled form.
    def debt_draft(rules, ai, kind)
      resolved = DEBT_KINDS.include?(kind) ? kind : DIRECTION_KIND.fetch(ai.direction.to_s, "debt_out")
      contact = rules.contact_name.presence || ai.person

      unresolved = []
      unresolved << :amount if rules.amount.blank?
      unresolved << :debt if contact.blank?

      Draft.new(
        kind: resolved, amount: rules.amount,
        contact_name: contact,
        direction: rules.direction.presence || (resolved == "debt_in" ? "borrowed" : "lent"),
        transaction_date: rules.transaction_date, description: rules.description,
        note: raw_note, unresolved: unresolved
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
