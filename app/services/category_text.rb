# frozen_string_literal: true

# Shared normaliser for category matching: accent-, case- and punctuation-insensitive.
# "Café"/"cafe", "j'adore"/"jadore", "🛒 Groceries"/"groceries", "woro-woro"/"woro woro"
# all collapse to the same token.
module CategoryText
  module_function

  def normalize(value)
    I18n.transliterate(value.to_s).downcase.gsub(/[^a-z0-9]+/, "")
  end
end
