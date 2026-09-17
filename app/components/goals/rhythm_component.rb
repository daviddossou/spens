# frozen_string_literal: true

class Goals::RhythmComponent < ViewComponent::Base
  def initialize(progress:)
    @progress = progress
  end

  private

  attr_reader :progress

  delegate :money, to: :helpers
end
