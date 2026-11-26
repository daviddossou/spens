# frozen_string_literal: true

module StatementImports
  # Gives each expense/income line its category through the SAME pipeline as quick add
  # (QuickEntry::Coordinator): the space's learned vocabulary and aliases first, then category
  # memory, and Claude only when the rules found nothing. A category the rules found is trusted;
  # one only the AI found is shown as uncertain, to review.
  class Categorizer
    CATEGORY_KINDS = %w[expense income].freeze
    # Nothing found: file the line under "Other" rather than ask the user to fill it in. Set to
    # false to require a category again (the review then blocks the save).
    FALLBACK_TO_OTHER = true
    FALLBACK_KEYS = { "expense" => "other_expense", "income" => "other_income" }.freeze
    THREADS = 4

    def self.call(import)
      new(import).call
    end

    def initialize(import)
      @import = import
      @space = import.space
      @locale = @space.locale.presence || I18n.default_locale
    end

    def call
      lines = @import.lines.proposed.where(kind: CATEGORY_KINDS).to_a
      @spent_at = lines.select { _1.kind == "expense" }.map { merchant_key(_1) }.to_set
      # One decision per merchant and side: the same shop gets the same category on every line.
      groups = lines.group_by { [ _1.kind, merchant_key(_1) ] }.values
      queue = Queue.new
      groups.each { queue << _1 }
      results = Concurrent::Map.new
      Array.new([ THREADS, groups.size ].min) do
        Thread.new do
          Rails.application.executor.wrap do
            while (group = (queue.pop(true) rescue nil))
              results[group.first.id] = categorize(group.first)
            end
          end
        end
      end.each(&:join)

      groups.each do |group|
        name, source, trace, flag = results[group.first.id]
        group.each do |line|
          trace = trace&.merge("text" => phrase(line)) unless line == group.first
          line.update!(transaction_type_name: name, category_source: source, categorization: trace,
                       flags: flag ? line.flags | [ flag ] : line.flags)
        end
      end
    end

    private

    def merchant_key(line)
      CategoryText.normalize(line.label.to_s.gsub(/\d+/, ""))
    end

    # => [transaction_type_name, "rules" | "ai" | nil, what the pipeline saw]. The last part is what
    # quick add logs on a QuickEntryAttempt, so a saved line feeds the same learners.
    def categorize(line)
      text = phrase(line)
      parse = QuickEntry::Coordinator.call(text, space: @space, locale: @locale, ai: false)
      source = "rules" if fits?(parse.draft, line)
      if source.nil? && QuickEntry::Coordinator.ai_enabled?
        parse = QuickEntry::Coordinator.call(text, space: @space, locale: @locale, ai: true)
        source = "ai" if fits?(parse.draft, line)
      end
      name = parse.draft.transaction_type_name if source
      name = subcategory_name(parse) || name if source == "ai"
      return refund(text, parse) if line.kind == "income" && source != "rules" && spent_here?(line)
      proposed = name
      if name.nil? && FALLBACK_TO_OTHER
        name = TransactionTaxonomy.name(FALLBACK_KEYS.fetch(line.kind), @locale)
        source = "fallback"
      end
      [ name, source, trace(text, proposed, parse) ]
    rescue StandardError => e
      Rails.logger.warn("StatementImports::Categorizer line #{line.id}: #{e.message}")
      [ nil, nil, nil ]
    end

    # What quick add logs on a QuickEntryAttempt: the phrase, the proposal, the raw drafts.
    def trace(text, proposed, parse)
      { "text" => text, "locale" => @locale.to_s, "proposed" => proposed,
        "draft" => parse.draft.to_form_payload.as_json, "ai_draft" => parse.ai_draft }
    end

    # Money in from a merchant the user spends at (an Uber Eats or KoRo refund): a refund, not an
    # income category guessed by the AI.
    def spent_here?(line)
      return true if @spent_at.include?(merchant_key(line))

      expense = QuickEntry::Coordinator.call(phrase(line).delete_prefix("#{received_word} "), space: @space, locale: @locale, ai: false).draft
      expense.kind == "expense" && expense.transaction_type_name.present?
    end

    def refund(text, parse)
      name = TransactionTaxonomy.name("refund", @locale)
      [ name, "rules", trace(text, name, parse), "refund" ]
    end

    def received_word
      I18n.t("statement_imports.received_word", locale: @locale)
    end

    # Read like a quick-add phrase: the amount, then the words of the label that can carry a category.
    # Operation numbers go, and so do the words that would make the parser read another kind
    # ("TRANSFER INTERNATIONAL … aide familiale" is an expense here: our rules already decided the
    # kind, the parser is only asked for the category). Money in is said as received, as a user
    # would type it, so the parser looks on the income side.
    def phrase(line)
      label = line.label.to_s.gsub(/\d{4,}|[*@]+/, " ")
      label = kind_words.reduce(label) { |text, word| text.gsub(/(?<![[:alnum:]])#{Regexp.escape(word)}(?![[:alnum:]])/i, " ") }.squish
      received = received_word if line.kind == "income"
      [ received, line.amount.abs.to_i, label ].compact.join(" ")
    end

    # Kind keywords of both languages: statements mix French and English ("TRANSFER", "RETRAIT").
    def kind_words
      @kind_words ||= %w[fr en].flat_map do |lang|
        QuickEntry::Keywords.kind(lang).values_at("transfer", "debt_lent", "debt_borrowed", "debt_repaid").flatten.compact
      end.uniq.sort_by { -_1.length }
    end

    # Claude stayed on a parent ("Salaire & Emploi"): a bank line is better filed under the
    # child it named ("Salaire"), still shown as uncertain.
    def subcategory_name(parse)
      key = parse.ai_draft&.dig("subcategory_key") or return nil
      TransactionTaxonomy.name(key, @locale)
    end

    # The category must belong to the line's side: an income category never lands on an expense.
    def fits?(draft, line)
      draft.transaction_type_name.present? && draft.kind == line.kind
    end
  end
end
