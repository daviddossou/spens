# frozen_string_literal: true

module Transactions
  # @label Transactions search
  class SearchComponentPreview < ViewComponent::Preview
    # Empty search field
    def default
      render Transactions::SearchComponent.new(query: nil)
    end

    # With a query typed
    def with_query
      render Transactions::SearchComponent.new(query: "zem")
    end
  end
end
