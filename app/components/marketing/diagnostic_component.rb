# frozen_string_literal: true

class Marketing::DiagnosticComponent < ViewComponent::Base
  def initialize(diagnostic_accents:, diagnostic_goals:)
    @diagnostic_accents = diagnostic_accents
    @diagnostic_goals = diagnostic_goals
  end

  private

  attr_reader :diagnostic_accents, :diagnostic_goals
end
