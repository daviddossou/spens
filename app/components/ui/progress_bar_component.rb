# frozen_string_literal: true

class Ui::ProgressBarComponent < ViewComponent::Base
  def initialize(percentage:, classes: "progress-bar", fill_class: "progress-fill", label: nil, value_text: nil, width: nil)
    @percentage = percentage
    @classes = classes
    @fill_class = fill_class
    @label = label
    @value_text = value_text
    @width = width
  end

  private

  attr_reader :percentage, :classes, :fill_class, :label, :value_text, :width

  def bounded_percentage
    percentage.clamp(0, 100)
  end

  def bounded_width
    (width || percentage).clamp(0, 100)
  end
end
