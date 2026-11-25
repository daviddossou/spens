# frozen_string_literal: true

module StatementImports
  # Gives each expense/income line its category through the SAME pipeline as quick add
  # (QuickEntry::Coordinator): the space's learned vocabulary and aliases first, then category
  # memory, and Claude only when the rules found nothing. A category the rules found is trusted;
  # one only the AI found is shown as uncertain, to review.
  class Categorizer
    CATEGORY_KINDS = %w[expense income].freeze
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
      queue = Queue.new
      lines.each { queue << _1 }
      results = Concurrent::Map.new
      Array.new([ THREADS, lines.size ].min) do
        Thread.new do
          Rails.application.executor.wrap do
            while (line = (queue.pop(true) rescue nil))
              results[line.id] = categorize(line)
            end
          end
        end
      end.each(&:join)

      lines.each do |line|
        name, source, categorization = results[line.id]
        line.update!(transaction_type_name: name, category_source: source, categorization: categorization)
      end
    end

    private

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
      [ name, source, { "text" => text, "locale" => @locale.to_s, "proposed" => name,
                    "draft" => parse.draft.to_form_payload.as_json, "ai_draft" => parse.ai_draft } ]
    rescue StandardError => e
      Rails.logger.warn("StatementImports::Categorizer line #{line.id}: #{e.message}")
      [ nil, nil, nil ]
    end

    # Read like a quick-add phrase: the amount, then the label without operation numbers, so the
    # parser has one clean amount and the words that carry the category. Money in is said as
    # received, as a user would type it, so the parser looks on the income side.
    def phrase(line)
      label = line.label.to_s.gsub(/\d{4,}|\*+/, " ").squish
      received = I18n.t("statement_imports.received_word", locale: @locale) if line.kind == "income"
      [ received, line.amount.abs.to_i, label ].compact.join(" ")
    end

    # The category must belong to the line's side: an income category never lands on an expense.
    def fits?(draft, line)
      draft.transaction_type_name.present? && draft.kind == line.kind
    end
  end
end
