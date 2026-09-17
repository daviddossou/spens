# frozen_string_literal: true

class Debts::WrittenOffComponent < ViewComponent::Base
  def initialize(debt:)
    @debt = debt
  end

  private

  attr_reader :debt

  delegate :closed_debt_detail, :debt_status_label, :money, to: :helpers
end
