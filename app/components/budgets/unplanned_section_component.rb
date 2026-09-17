# frozen_string_literal: true

class Budgets::UnplannedSectionComponent < ViewComponent::Base
  def initialize(month:, unplanned:, read_only:)
    @month = month
    @unplanned = unplanned
    @read_only = read_only
  end

  private

  attr_reader :month, :unplanned, :read_only

  delegate :money, to: :helpers
end
