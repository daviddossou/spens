# frozen_string_literal: true

# Quick-add AI fallback. Two providers, both DORMANT unless configured, so dev/test/CI stay
# fully rules-based:
#
# - Anthropic (Claude Haiku) is the primary decomposer. Enabled once an API key is present
#   (Rails credentials `anthropic.api_key`, or ENV["ANTHROPIC_API_KEY"] as an override).
# - The OpenAI-compatible path (self-hosted Ollama) remains as a fallback if only
#   QUICK_ENTRY_LLM_URL is set.
Rails.application.config.x.quick_entry_llm = {
  base_url: ENV["QUICK_ENTRY_LLM_URL"],
  model: ENV.fetch("QUICK_ENTRY_LLM_MODEL", "qwen2.5:3b"),
  api_key: ENV["QUICK_ENTRY_LLM_API_KEY"]
}

# Off in test so specs never hit the network (the key lives in shared credentials); on in
# development and production. Specs that exercise the parser stub the config/HTTP directly.
anthropic_api_key =
  unless Rails.env.test?
    ENV["ANTHROPIC_API_KEY"].presence ||
      begin
        Rails.application.credentials.dig(:anthropic, :api_key)
      rescue StandardError
        nil
      end
  end

Rails.application.config.x.quick_entry_anthropic = {
  api_key: anthropic_api_key,
  model: ENV.fetch("ANTHROPIC_MODEL", "claude-haiku-4-5-20251001")
}
