# frozen_string_literal: true

module Transactions
  # @label Fact row
  class FactRowComponentPreview < ViewComponent::Preview
    # A fact that opens its selector in the modal
    def default
      render Transactions::FactRowComponent.new(label: "Category", value: "Groceries", url: "#")
    end

    # A fact that navigates away at top level
    def top_level_link
      render Transactions::FactRowComponent.new(label: "Account", value: "Wave", url: "#", frame: "_top")
    end

    # A fact that cannot be changed here
    def static
      render Transactions::FactRowComponent.new(label: "Date", value: "March 5, 2026")
    end
  end
end
