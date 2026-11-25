# frozen_string_literal: true

require "net/http"
require "json"
require "base64"

module StatementImports
  # Reads ONE capture (screenshot or PDF) with Claude's vision and returns the raw tool input plus
  # what it cost, untouched: our own rules run afterwards (Proposer) so every read stays
  # replayable against a future reader.
  class Reader
    API_URL = "https://api.anthropic.com/v1/messages"
    API_VERSION = "2023-06-01"
    TIMEOUT = 150
    # A 5-page statement is ~70 lines, ~10k output tokens.
    MAX_TOKENS = 16_000
    TOOL_NAME = "record_lines"

    class Error < StandardError; end

    def self.config
      Rails.application.config.x.statement_import || {}
    end

    def self.enabled?
      config[:api_key].present?
    end

    def initialize(space:, user:, account: nil, today: Date.current)
      @space = space
      @user = user
      @account = account
      @today = today
    end

    # => { "model", "seconds", "usage", "stop_reason", "result" => { "source", "account", "lines" } }
    def read(blob)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = post_json(request_body(blob))
      block = Array(response["content"]).find { |b| b["type"] == "tool_use" && b["name"] == TOOL_NAME }
      raise Error, "no #{TOOL_NAME} call (stop_reason: #{response['stop_reason']})" unless block

      {
        "model" => response["model"],
        "seconds" => (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(2),
        "usage" => response["usage"]&.slice("input_tokens", "output_tokens"),
        "stop_reason" => response["stop_reason"],
        "result" => block["input"]
      }
    end

    private

    def request_body(blob)
      body = {
        model: self.class.config[:model],
        max_tokens: MAX_TOKENS,
        system: system_prompt,
        messages: [ { role: "user", content: [ content_block(blob), { type: "text", text: "Extract the lines." } ] } ],
        tools: [ tool_schema ],
        tool_choice: { type: "tool", name: TOOL_NAME }
      }
      # Haiku 5.5 thinks by default, which a forced tool call does not allow.
      body[:thinking] = { type: "disabled" } if body[:model].to_s.match?(/haiku-5/)
      body
    end

    def content_block(blob)
      data = Base64.strict_encode64(blob.download)
      if blob.content_type == "application/pdf"
        { type: "document", source: { type: "base64", media_type: "application/pdf", data: data } }
      else
        { type: "image", source: { type: "base64", media_type: blob.content_type, data: data } }
      end
    end

    def system_prompt
      <<~TXT
        You read screenshots or PDF statements from banks, mobile-money apps and their SMS, for a personal
        budgeting app. Extract every line that could be a money movement, then call #{TOOL_NAME} once.

        Rules:
        - Copy what is shown. Never invent a date, an amount or a fee. Use null when unreadable or absent.
        - amount: signed number in the shown currency (out = negative, in = positive), as a plain number.
          Mind locale separators: "1.381.314" or "1 381 314" is 1381314; "12.34 USD" is 12.34.
          XOF, XAF and GNF have no decimals: "100.005 F" is 100005.
        - fee: only when the source states it separately. If the shown amount already includes the fee, set fee_included.
        - status:
          ok = money actually moved; declined = failed/rejected/"a echoue"; pending = not yet received/validated;
          card_check = 0.00 verification; not_transaction = OTP, promo, balance-only, info message, period total/closing balance;
          cut_off = line cut at the screen edge and not fully readable;
          duplicate = the same movement already listed in THIS capture (e.g. a USD card payment and its XOF debit).
          Only use duplicate when the other line is visible here.
        - For not_transaction lines, never copy codes, passwords or PINs: describe them in a few words.
        - kind: your best guess: expense, income, transfer (between the user's own accounts), debt_in, debt_out.
          Money sent to another person is an expense unless the text says it is a loan or a repayment.
          transfer only when the text names one of the user's own accounts or the holder's own name/account number.
          If unsure, pick expense/income and set needs_review.
        - Years: if the capture shows no year, assume the most recent past date before today.

        The user is #{holder_name}. Their accounts: #{account_list}. Default currency: #{@space.currency}.
        #{"This capture is from their account \"#{@account.name}\". " if @account}Today is #{@today.iso8601}.
      TXT
    end

    def holder_name
      [ @user.first_name, @user.last_name ].compact_blank.join(" ").presence || "unknown"
    end

    def account_list
      @space.accounts.active.order(:name).map { |a| a.name.sub(/\A[^[:alnum:]]+/, "").strip }
            .compact_blank.join("; ").presence || "none yet"
    end

    def tool_schema
      {
        name: TOOL_NAME,
        description: "Record what the capture shows.",
        input_schema: {
          type: "object",
          properties: {
            source: { type: "string", description: "e.g. 'MTN MoMo SMS', 'NSIA PDF statement', 'Trade Republic app'" },
            account: { type: [ "string", "null" ], description: "which of the user's accounts this capture belongs to" },
            lines: { type: "array", items: line_schema }
          },
          required: %w[source lines]
        }
      }
    end

    def line_schema
      {
        type: "object",
        properties: {
          date: { type: [ "string", "null" ], description: "YYYY-MM-DD or YYYY-MM-DD HH:MM" },
          label: { type: "string", description: "merchant / counterparty / description as shown" },
          amount: { type: [ "number", "null" ] },
          currency: { type: [ "string", "null" ] },
          fee: { type: [ "number", "null" ] },
          fee_included: { type: "boolean" },
          balance: { type: [ "number", "null" ] },
          reference: { type: [ "string", "null" ], description: "transaction id / ref, and any user note" },
          status: { type: "string", enum: StatementImportLine::STATUSES },
          kind: { type: [ "string", "null" ], enum: [ "expense", "income", "transfer", "debt_in", "debt_out", nil ] },
          needs_review: { type: "boolean" },
          why: { type: [ "string", "null" ], description: "a few words when status != ok or needs_review" }
        },
        required: %w[date label amount status kind]
      }
    end

    def post_json(body)
      uri = URI(API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = TIMEOUT

      request = Net::HTTP::Post.new(uri)
      request["content-type"] = "application/json"
      request["x-api-key"] = self.class.config[:api_key]
      request["anthropic-version"] = API_VERSION
      request.body = body.to_json

      response = http.request(request)
      raise Error, "HTTP #{response.code}: #{response.body.to_s[0, 300]}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end
  end
end
