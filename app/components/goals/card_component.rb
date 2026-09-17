# frozen_string_literal: true

class Goals::CardComponent < ViewComponent::Base
  def initialize(progress:)
    @progress = progress
  end

  private

  attr_reader :progress

  delegate :goal_rhythm_text, :goal_status_chip, :money_pair, to: :helpers
end
