# frozen_string_literal: true

class Marketing::GuideStepComponent < ViewComponent::Base
  def initialize(title:, description:, phase:, number: nil)
    @title = title
    @description = description
    @phase = phase
    @number = number
  end

  private

  attr_reader :title, :description, :phase, :number
end
