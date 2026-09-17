# frozen_string_literal: true

module Transactions
  # @label Timeline pagination
  class PaginationComponentPreview < ViewComponent::Preview
    # More pages to load: spinner (hidden until scrolling) and trigger
    def default
      render Transactions::PaginationComponent.new(has_more: true)
    end

    # Last page: no trigger
    def last_page
      render Transactions::PaginationComponent.new(has_more: false)
    end

    # The spinner forced visible
    def loading
      render_with_template(locals: { component: Transactions::PaginationComponent.new(has_more: true) })
    end
  end
end
