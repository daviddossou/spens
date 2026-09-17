# frozen_string_literal: true

module Accounts
  # @label Archived account row
  class ArchivedRowComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # An archived account with the balance it was frozen at
    def default
      account = build_account(name: "Old wallet", balance: 12_500, archived_at: 2.months.ago)
      render with_helpers(Accounts::ArchivedRowComponent.new(account: account))
    end

    # Archived while empty
    def zero_balance
      account = build_account(name: "Closed tontine", balance: 0, archived_at: 1.year.ago)
      render with_helpers(Accounts::ArchivedRowComponent.new(account: account))
    end
  end
end
