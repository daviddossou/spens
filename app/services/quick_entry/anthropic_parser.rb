# frozen_string_literal: true

require "net/http"
require "json"

module QuickEntry
  # The primary AI decomposer: Claude Haiku over the Anthropic Messages API, using tool-use so
  # the output is strict, validated JSON (no free-text parsing). DISABLED unless an API key is
  # configured, so dev/test/CI stay fully rules-based.
  #
  # It classifies the kind and extracts what the rules couldn't — a category (chosen from our
  # OWN parent taxonomy, with the children sent as hints so a word like "coca" lands on the
  # right parent), the salient phrase (the human note), the two accounts (transfer), or the
  # person + direction (debt). We re-resolve the category against the taxonomy; the model never
  # invents a category name. Returns the same shape as LlmParser so the Coordinator is agnostic.
  API_URL = "https://api.anthropic.com/v1/messages"
  API_VERSION = "2023-06-01"

  class AnthropicParser
    TIMEOUT = 12
    MAX_TOKENS = 512
    TOOL_NAME = "record_entry"
    DIRECTIONS = { "lent" => "lent", "lend" => "lent", "loaned" => "lent",
                   "borrowed" => "borrowed", "borrow" => "borrowed" }.freeze

    Result = Data.define(:kind, :amount, :category_key, :category_name, :phrase, :label,
                         :from_account, :to_account, :person, :direction) do
      def initialize(kind:, amount: nil, category_key: nil, category_name: nil, phrase: nil,
                     label: nil, from_account: nil, to_account: nil, person: nil, direction: nil)
        super
      end
    end

    def self.config
      Rails.application.config.x.quick_entry_anthropic || {}
    end

    def self.enabled?
      config[:api_key].present?
    end

    def initialize(space:, locale: I18n.locale)
      @space = space
      @locale = locale
    end

    def parse(text)
      return nil unless self.class.enabled?

      data = complete(text) or return nil
      build_result(data)
    rescue StandardError => e
      Rails.logger.warn("QuickEntry::AnthropicParser failed: #{e.message}")
      nil
    end

    private

    # Re-resolve the model's category label against our taxonomy/aliases — never trust a name
    # it made up. Account/person/direction pass through for the Coordinator to route.
    def build_result(data)
      category = data["category"].to_s
      key = category.present? && (CategoryAliasMatcher.match(category) || TransactionTaxonomy.key_for_name(category))

      Result.new(
        kind: data["kind"].presence,
        amount: positive_amount(data["amount"]),
        category_key: key || nil,
        category_name: key ? TransactionTaxonomy.name(key, @locale) : nil,
        phrase: clean_phrase(data["phrase"]),
        label: sanitize_label(data["label"]),
        from_account: data["from_account"].presence,
        to_account: data["to_account"].presence,
        person: data["person"].presence,
        direction: DIRECTIONS[data["direction"].to_s.downcase]
      )
    end

    def positive_amount(value)
      return nil if value.nil?

      amount = value.to_f
      amount.positive? ? amount : nil
    end

    # The note is the human phrase, never the amount. The model is asked to omit it but small
    # models sometimes don't, so strip any standalone number token ("500", "5k", "5 000").
    def clean_phrase(phrase)
      cleaned = phrase.to_s.gsub(/\b\d[\d.,\s]*\d?\s*(?:k|m)?\b/i, " ").squeeze(" ").strip
      cleaned.presence
    end

    # The short title label ("Coca", "Déjeuner chez Fatou"): drop any leading emoji
    # and stray amount tokens, and keep it terse enough for a one-line title.
    def sanitize_label(label)
      cleaned = clean_phrase(label.to_s.sub(/\A[^[:alnum:]]+/, ""))
      cleaned && cleaned.length > 40 ? cleaned[0, 40].strip : cleaned
    end

    # POST the message with a forced tool call, then read the tool_use block's validated input.
    # Retries once on a transient failure (a cold outbound connection sometimes drops the first
    # request) so a hiccup falls back to the rules rather than dropping the user to a blank form.
    def complete(text)
      attempts = 0
      begin
        response = post_json(URI(API_URL), request_body(text))
        block = Array(response["content"]).find { |b| b["type"] == "tool_use" && b["name"] == TOOL_NAME }
        block && block["input"]
      rescue StandardError => e
        attempts += 1
        retry if attempts < 2

        Rails.logger.warn("QuickEntry::AnthropicParser request failed: #{e.message}")
        raise
      end
    end

    def request_body(text)
      {
        model: self.class.config[:model],
        max_tokens: MAX_TOKENS,
        system: system_prompt,
        messages: [ { role: "user", content: text } ],
        tools: [ tool_schema ],
        tool_choice: { type: "tool", name: TOOL_NAME }
      }
    end

    def tool_schema
      {
        name: TOOL_NAME,
        description: "Record the structured decomposition of a personal-finance message.",
        input_schema: {
          type: "object",
          properties: {
            kind: { type: "string", enum: %w[expense income transfer debt], description: "the transaction family" },
            amount: { type: %w[number null], description: "the amount stated, or null" },
            category: { type: %w[string null], description: "closest category from the list — a specific subcategory is better than its parent (expense/income only)" },
            phrase: { type: %w[string null], description: "the salient word(s) the entry is about — the human note (e.g. 'coca')" },
            label: { type: %w[string null], description: "a short Title-Case label for the list row, WITHOUT the amount (e.g. 'Coca', 'Déjeuner chez Fatou', 'Crédit téléphone'); expense/income only" },
            from_account: { type: %w[string null], description: "source account, transfer only, only if it appears in the message" },
            to_account: { type: %w[string null], description: "destination account, transfer only, only if it appears in the message" },
            person: { type: %w[string null], description: "the other person's name, debt only, only if it appears" },
            direction: { type: %w[string null], enum: [ "lent", "borrowed", nil ], description: "debt only" }
          },
          required: [ "kind" ]
        }
      }
    end

    def system_prompt
      <<~PROMPT
        You turn a short personal-finance message into structured data by calling the
        #{TOOL_NAME} tool. The message may be in English or French; amounts are in #{currency}.

        - "transfer" = moving the user's OWN money between TWO of their accounts (a source AND a
          destination). If only one account is involved, it is "income" or "expense".
        - "debt" = lending to or borrowing from a person. "lent"/"prêté"/"dépanné" = lent;
          "borrowed"/"emprunté" = borrowed. A repayment to/from a person is also a debt.
        - Use ONLY account or person names that actually appear in the message — never invent one.
        - "phrase" = the meaningful word(s) the entry is about (a product, a merchant, a reason),
          WITHOUT the amount. It becomes a searchable note.
        - "label" = a short, human, Title-Case title for the list row, WITHOUT the amount
          (e.g. "Coca", "Déjeuner chez Fatou", "Crédit téléphone"). For expense/income only;
          leave it null for transfers and debts (their title is composed from the accounts/people).

        For expense/income, set "category" to the closest match from this list. Prefer a
        specific subcategory (shown in parentheses) when it clearly fits; otherwise use its
        parent. Pick the closest even for unfamiliar or local words:
        #{category_list}
      PROMPT
    end

    def category_list
      %w[expense income].flat_map { |kind| TransactionTaxonomy.parent_keys(kind) }.filter_map do |key|
        label = clean_label(TransactionTaxonomy.name(key, @locale))
        next if label.blank?

        hints = TransactionTaxonomy.child_keys(key).map { |c| clean_label(TransactionTaxonomy.name(c, @locale)) }.reject(&:blank?)
        hints.any? ? "- #{label} (ex: #{hints.join(', ')})" : "- #{label}"
      end.join("\n")
    end

    # Taxonomy display names carry an emoji prefix; drop it for the prompt.
    def clean_label(name)
      name.to_s.sub(/\A[^[:alnum:]]+/, "").strip
    end

    def currency
      @space&.currency.presence || "the local currency"
    end

    def post_json(uri, body)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = http.read_timeout = TIMEOUT

      request = Net::HTTP::Post.new(uri)
      request["content-type"] = "application/json"
      request["x-api-key"] = self.class.config[:api_key]
      request["anthropic-version"] = API_VERSION
      request.body = body.to_json

      JSON.parse(http.request(request).body)
    end
  end
end
