# frozen_string_literal: true

class Analytics::SavingsHistoryComponent < ViewComponent::Base
  def initialize(set_aside:)
    @set_aside = set_aside
  end

  private

  attr_reader :set_aside

  delegate :money, to: :helpers
end
