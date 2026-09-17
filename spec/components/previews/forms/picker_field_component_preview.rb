# frozen_string_literal: true

module Forms
  # @label Picker Field
  class PickerFieldComponentPreview < ViewComponent::Preview
    Record = Struct.new(:account_name, :transaction_type_name, :from_account_name, :to_account_name)

    ACCOUNT_ROWS = [
      { value: "Bank", label: "Bank", icon: "🏦", meta: "120 k" },
      { value: "Cash", label: "Cash", icon: "💵", meta: "5 k" },
      { value: "Savings", label: "Savings", icon: "🐖", meta: "40 k" }
    ].freeze

    CATEGORY_ROWS = [
      { value: "Rent", label: "Rent", icon: "🏠", group: "planned" },
      { value: "Groceries", label: "Groceries", icon: "🛒", group: "planned" },
      { value: "Taxi", label: "Taxi", icon: "🚕", group: "rest" }
    ].freeze

    # Selected account with help text
    def default
      render_with_template locals: { record: Record.new("Bank"), rows: ACCOUNT_ROWS }
    end

    # Nothing chosen yet: the placeholder reads as empty
    def empty
      render_with_template locals: { record: Record.new(nil), rows: ACCOUNT_ROWS }
    end

    # A stored value no longer in the list still shows
    def stale_value
      render_with_template locals: { record: Record.new("Old savings"), rows: ACCOUNT_ROWS }
    end

    # Grouped categories with creation allowed
    def grouped_categories
      render_with_template locals: { record: Record.new(nil, "Rent"), rows: CATEGORY_ROWS }
    end

    # Two chained pickers (transfer from / to)
    def chained_transfer
      render_with_template locals: { record: Record.new(nil, nil, "Bank", nil), rows: ACCOUNT_ROWS }
    end
  end
end
