# frozen_string_literal: true

class Transactions::MovementHeroComponent < ViewComponent::Base
  def initialize(transaction:, row:)
    @transaction = transaction
    @row = row
  end

  private

  attr_reader :transaction, :row

  delegate :money, to: :helpers
end
