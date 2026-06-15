# frozen_string_literal: true

# Quick-add AI fallback (Phase 3). Off unless a base URL is configured — so dev/test stay
# fully rules-based. In production QUICK_ENTRY_LLM_URL points at the self-hosted Ollama Kamal
# accessory (http://spens-ollama:11434/v1); see config/deploy.yml.
Rails.application.config.x.quick_entry_llm = {
  base_url: ENV["QUICK_ENTRY_LLM_URL"],
  model: ENV.fetch("QUICK_ENTRY_LLM_MODEL", "qwen2.5:3b"),
  api_key: ENV["QUICK_ENTRY_LLM_API_KEY"]
}
