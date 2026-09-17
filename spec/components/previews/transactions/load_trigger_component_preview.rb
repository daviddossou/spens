# frozen_string_literal: true

module Transactions
  # @label Load trigger
  class LoadTriggerComponentPreview < ViewComponent::Preview
    # The invisible sentinel the infinite-scroll controller watches
    def default
      render Transactions::LoadTriggerComponent.new
    end
  end
end
