# frozen_string_literal: true

require "net/http"
require "json"

module QuickEntry
  # Provider-agnostic LLM fallback over an OpenAI-compatible chat endpoint (default target:
  # the self-hosted Ollama Kamal accessory). DISABLED unless config.x.quick_entry_llm.base_url
  # is set, so it stays dormant outside production. The model classifies the kind and extracts
  # the structure the rules couldn't — a category guess + its word (expense/income), the two
  # accounts (transfer), or the person + direction (debt). We resolve the category against our
  # own taxonomy; the model never names a category (it doesn't know local slang like "zem").
  class LlmParser
    TIMEOUT = 12
    DIRECTIONS = { "lent" => "lent", "lend" => "lent", "loaned" => "lent",
                   "borrowed" => "borrowed", "borrow" => "borrowed" }.freeze

    Result = Data.define(:kind, :amount, :category_key, :category_name, :phrase,
                         :from_account, :to_account, :person, :direction) do
      def initialize(kind:, amount: nil, category_key: nil, category_name: nil, phrase: nil,
                     from_account: nil, to_account: nil, person: nil, direction: nil)
        super
      end
    end

    def self.config
      Rails.application.config.x.quick_entry_llm || {}
    end

    def self.enabled?
      config[:base_url].present?
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
      Rails.logger.warn("QuickEntry::LlmParser failed: #{e.message}")
      nil
    end

    private

    # We resolve the model's category guess against our own taxonomy/aliases — never let it
    # invent a category name. Account/person/direction are passed through for the Coordinator
    # to resolve and route.
    def build_result(data)
      category = data["category"].to_s
      key = category.present? && (CategoryAliasMatcher.match(category) || TransactionTaxonomy.key_for_name(category))

      Result.new(
        kind: data["kind"].presence,
        amount: positive_amount(data["amount"]),
        category_key: key || nil,
        category_name: key ? TransactionTaxonomy.name(key, @locale) : nil,
        phrase: data["phrase"].presence,
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

    def complete(text)
      uri = URI.join(self.class.config[:base_url].chomp("/") + "/", "chat/completions")
      response = post_json(uri, completion_body(text))
      content = response.dig("choices", 0, "message", "content") or return nil
      JSON.parse(content)
    rescue JSON::ParserError
      nil
    end

    def completion_body(text)
      {
        model: self.class.config[:model] || "qwen2.5:3b",
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: text }
        ],
        temperature: 0,
        response_format: { type: "json_object" }
      }
    end

    # Built from the single sources of truth — the taxonomy (in the user's locale) and the
    # space's currency — so it never duplicates or drifts from the app's data. The model
    # classifies into our real parent categories; "phrase" feeds alias learning later.
    def system_prompt
      <<~PROMPT
        You turn a short personal-finance message into structured data. The message may be in
        English or French; amounts are in #{currency}.

        Reply with ONLY a JSON object and nothing else:
        {"kind": "expense" | "income" | "transfer" | "debt",
         "amount": <number or null>,
         "category": "<one label from the list below — expense/income only>",
         "phrase": "<the word(s) the category is based on — expense/income only>",
         "from_account": "<source account — transfer only>",
         "to_account": "<destination account — transfer only>",
         "person": "<the other person's name — debt only>",
         "direction": "lent" | "borrowed" (debt only)}

        - "transfer" = moving the user's OWN money between TWO of their accounts (a source AND a
          destination). If only one account is involved, it is "income" or "expense", NOT a transfer.
        - "debt" = lending to or borrowing from a person. "lent"/"prêté"/"dépanné" = lent;
          "borrowed"/"emprunté" = borrowed. A repayment to/from a person is also a debt.
        - Use ONLY account or person names that actually appear in the message — never invent one.
        - Use null for any field that doesn't apply or isn't stated.

        For expense/income, choose "category" as the closest match from this list, even for
        unfamiliar or local words:
        #{category_list}
      PROMPT
    end

    def category_list
      category_labels.map { |label| "- #{label}" }.join("\n")
    end

    def category_labels
      @category_labels ||=
        (TransactionTaxonomy.parent_keys("expense") + TransactionTaxonomy.parent_keys("income"))
        .map { |key| clean_label(TransactionTaxonomy.name(key, @locale)) }
        .reject(&:blank?)
    end

    # Taxonomy display names carry an emoji prefix; drop it for the prompt (resolution
    # normalises it away anyway).
    def clean_label(name)
      name.to_s.sub(/\A[^[:alnum:]]+/, "").strip
    end

    def currency
      @space&.currency.presence || "the local currency"
    end

    def post_json(uri, body)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = http.read_timeout = TIMEOUT

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      if (key = self.class.config[:api_key]).present?
        request["Authorization"] = "Bearer #{key}"
      end
      request.body = body.to_json

      JSON.parse(http.request(request).body)
    end
  end
end
