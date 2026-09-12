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

    # ai: false keeps it to the rules parser — what the form's live fill runs on every keystroke.
    def self.call(text, space:, locale: I18n.locale, context: {}, ai: true)
      new(text, space: space, locale: locale, context: context, ai: ai).call
    end

    def self.ai_enabled?
      AnthropicParser.enabled? || LlmParser.enabled?
    end

    def initialize(text, space:, locale: I18n.locale, context: {}, ai: true)
      @text = text
      @ai = ai
      @space = space
      @locale = locale
      # The sheet's pill; applied only where the phrase said nothing.
      @context = context || {}
    end

    def call
      rules = Parser.parse(@text, space: @space, locale: @locale).with(note: raw_note)
      rules = apply_context(DebtLinker.link(rules, text: @text, space: @space))
      return Result.new(draft: rules, ai_draft: nil) if !@ai || rules.confident? || form_ready?(rules) || !ai_parser

      ai = ai_parser.new(space: @space, locale: @locale).parse(@text)
      return Result.new(draft: rules, ai_draft: nil) unless ai

      Result.new(draft: apply_context(merge(rules, ai)), ai_draft: ai_draft(ai))
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
    # Rules keep precedence when they detected a structural kind; otherwise the AI's kind wins —
    # except a transfer with only one end named: a mentioned account ("… sur mon MTN") never
    # turns a purchase into a transfer. Two named ends (one may be new) open the transfer form.
    def merge(rules, ai)
      kind = structural?(rules.kind) ? rules.kind : ai.kind
      kind = "expense" if !structural?(rules.kind) && !ai_structural_backed?(kind, ai)

      case kind
      when "transfer"          then transfer_draft(rules, ai)
      when "debt", *DEBT_KINDS then debt_draft(rules, ai, kind)
      else                          backfill(rules, ai)
      end
    end

    # The AI's own structural claim needs evidence in the phrase: a transfer names both ends
    # (one of them an existing account), a debt names the person. Otherwise it's a purchase
    # that happens to mention an account or a name.
    def ai_structural_backed?(kind, ai)
      case kind
      when "transfer" then ai.from_account.present? && ai.to_account.present? &&
                           (existing_account(ai.from_account) || existing_account(ai.to_account)).present?
      when "debt", *DEBT_KINDS then ai.person.present?
      else true
      end
    end

    def structural?(kind)
      kind == "transfer" || DEBT_KINDS.include?(kind)
    end

    # Expense/income: keep what the rules resolved, let the model fill the gaps, and never
    # leave it uncategorised — fall back to the "Other" default so the entry always lands
    # somewhere (the note keeps the detail; the user can recategorise).
    def backfill(rules, ai)
      kind = rules.transaction_type_name.present? ? rules.kind : (ai_kind(ai).presence || rules.kind)
      type_name = rules.transaction_type_name.presence || ai.category_name.presence || default_category_name(kind)
      amount, amount_settled = settle_amount(rules, ai)

      unresolved = []
      unresolved << :amount if amount.blank? || !amount_settled

      Draft.new(
        kind: kind, amount: amount, account_name: rules.account_name,
        transaction_type_name: type_name, fee_amount: rules.fee_amount,
        transaction_date: rules.transaction_date, description: rules.description,
        note: raw_note, label: ai.label, unresolved: unresolved,
        amount_candidates: rules.amount_candidates
      )
    end

    # The rules hesitated between several numbers: the AI's pick settles it only when it is
    # one of them (a computed total like 25 × 10 isn't); otherwise the user confirms.
    def settle_amount(rules, ai)
      return [ rules.amount || ai.amount, true ] unless rules.amount_ambiguous?
      return [ ai.amount, true ] if ai.amount && rules.amount_candidates.any? { |c| c.to_f == ai.amount.to_f }

      [ rules.amount, false ]
    end

    # A category belongs to a kind: the model's stated kind can't contradict the category it
    # picked (an expense category never makes an income).
    # Only income/expense come out of here (backfill's world); anything else falls back to rules.
    def ai_kind(ai)
      category_kind = ai.category_key.presence && TransactionTaxonomy.kind_of(ai.category_key)
      return category_kind if %w[income expense].include?(category_kind)

      %w[income expense].include?(ai.kind) ? ai.kind : nil
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

      amount, amount_settled = settle_amount(rules, ai)
      unresolved = []
      unresolved << :amount if amount.blank? || !amount_settled
      unresolved << :from_account if from.blank?
      unresolved << :to_account if to.blank?

      Draft.new(
        kind: "transfer", amount: amount, from_account_name: from, to_account_name: to,
        fee_amount: rules.fee_amount, transaction_date: rules.transaction_date,
        description: rules.description, note: raw_note, unresolved: unresolved,
        amount_candidates: rules.amount_candidates
      )
    end

    # A debt with a NEW person (a known one would already be linked by DebtLinker above). With a
    # clear direction and a resolved person + amount it auto-creates the counterparty on submit;
    # only a missing person/amount falls back to the prefilled form.
    def debt_draft(rules, ai, kind)
      resolved = DEBT_KINDS.include?(kind) ? kind : DIRECTION_KIND.fetch(ai.direction.to_s, "debt_out")
      contact = rules.contact_name.presence || ai.person

      amount, amount_settled = settle_amount(rules, ai)
      unresolved = []
      unresolved << :amount if amount.blank? || !amount_settled
      unresolved << :debt if contact.blank?

      Draft.new(
        kind: resolved, amount: amount,
        contact_name: contact,
        direction: rules.direction.presence || (resolved == "debt_in" ? "borrowed" : "lent"),
        transaction_date: rules.transaction_date, description: rules.description,
        note: raw_note, unresolved: unresolved, amount_candidates: rules.amount_candidates
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

    def apply_context(draft)
      draft = apply_goal_context(draft)
      draft = apply_account_context(draft)
      apply_person_context(draft)
    end

    # A goal entry is a deposit: a transfer into the goal's account.
    def apply_goal_context(draft)
      target = @context[:to_account_name]
      return draft if target.blank?

      from = draft.from_account_name.presence || draft.account_name.presence
      unresolved = draft.unresolved & [ :amount ]
      unresolved << :amount if draft.amount.blank? && unresolved.empty?
      unresolved << :from_account if from.blank?

      Draft.new(
        kind: "transfer", amount: draft.amount, from_account_name: from,
        to_account_name: target, fee_amount: draft.fee_amount,
        transaction_date: draft.transaction_date, description: draft.description,
        note: draft.note, unresolved: unresolved, amount_candidates: draft.amount_candidates
      )
    end

    def apply_account_context(draft)
      account = @context[:account_name]
      return draft if account.blank? || draft.account_name.present?
      return draft unless %w[expense income debt_in debt_out].include?(draft.kind)

      draft.with(account_name: account)
    end

    # Nameless, category-less movements are about the page's person; a
    # categorised phrase ("2000 zem") stays a plain expense.
    def apply_person_context(draft)
      person = @context[:contact_name]
      return draft if person.blank?
      return draft if draft.contact_name.present? || draft.debt_id.present?

      kind = person_kind(draft)
      return draft unless kind

      debts = @space.debts.ongoing.where("lower(trim(name)) = ?", person.to_s.strip.downcase).to_a
      attrs = { kind: kind, contact_name: person,
                unresolved: draft.unresolved - [ :debt, :category ] }
      attrs.merge!(debt_id: debts.first.id, direction: debts.first.direction) if debts.size == 1

      draft.with(**attrs)
    end

    def person_kind(draft)
      return draft.kind if DEBT_KINDS.include?(draft.kind)
      return "debt_out" if draft.kind == "debt"
      return nil if draft.transaction_type_name.present?

      { "income" => "debt_in", "expense" => "debt_out" }[draft.kind]
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
