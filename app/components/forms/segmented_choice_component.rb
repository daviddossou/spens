# frozen_string_literal: true

class Forms::SegmentedChoiceComponent < ViewComponent::Base
  def initialize(options:, classes: "pill-choice", button_class: "pill", active_class: "pill--active", data: {})
    @options = options
    @classes = classes
    @button_class = button_class
    @active_class = active_class
    @data = data
  end

  private

  attr_reader :options, :classes, :button_class, :active_class, :data
end
