# frozen_string_literal: true

# Service for handling transaction icon logic with caching
class TransactionIconService
  class << self
    # Get icon CSS class based on transaction kind
    def icon_class(kind, scope: "transaction-item")
      if kind == "income"
        "#{scope}__icon--income"
      elsif kind.include?("debt")
        "#{scope}__icon--debt"
      elsif kind.include?("transfer")
        "#{scope}__icon--transfer"
      else
        "#{scope}__icon--expense"
      end
    end

    # Get inline SVG for transaction icon with caching
    def icon_svg(kind)
      @icon_cache ||= {}

      # Handle generic "transfer" by defaulting to "transfer_in"
      icon_kind = kind == "transfer" ? "transfer_in" : kind

      @icon_cache[icon_kind] ||= read_icon_file(icon_kind)
    end

    # Get amount prefix (+ or -)
    def amount_prefix(kind)
      %w[income debt_in transfer_in].include?(kind) ? "+" : "-"
    end

    # Get amount CSS class based on kind
    def amount_class(kind, scope: "transaction-item")
      if kind == "income"
        "#{scope}__amount--income"
      elsif kind == "expense"
        "#{scope}__amount--expense"
      else
        "#{scope}__amount--neutral"
      end
    end

    # Get header CSS class for transaction show page
    def header_class(kind)
      if kind == "income"
        "transaction-show__header--income"
      elsif kind == "expense"
        "transaction-show__header--expense"
      else
        "transaction-show__header--neutral"
      end
    end

    # Get badge CSS class for transaction kind
    def badge_class(kind)
      if kind == "income"
        "transaction-show__badge--income"
      elsif kind.include?("debt")
        "transaction-show__badge--debt"
      elsif kind.include?("transfer")
        "transaction-show__badge--transfer"
      else
        "transaction-show__badge--expense"
      end
    end

    # Clear the icon cache (useful for tests)
    def clear_cache
      @icon_cache = {}
    end

    private

    def read_icon_file(icon_kind)
      icon_path = Rails.root.join("app", "assets", "images", "#{icon_kind}_icon.svg")
      return "" unless File.exist?(icon_path)

      File.read(icon_path).html_safe
    end
  end
end
