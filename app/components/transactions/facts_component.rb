# frozen_string_literal: true

class Transactions::FactsComponent < ViewComponent::Base
  def initialize(transaction:, editable:)
    @transaction = transaction
    @editable = editable
  end

  private

  attr_reader :transaction, :editable
end
