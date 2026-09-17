# frozen_string_literal: true

class Debts::ScheduleComponent < ViewComponent::Base
  def initialize(debt:, schedule:)
    @debt = debt
    @schedule = schedule
  end

  private

  attr_reader :debt, :schedule

  delegate :money, to: :helpers
end
