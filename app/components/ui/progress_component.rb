# frozen_string_literal: true

class Ui::ProgressComponent < ViewComponent::Base
  def initialize(
    current_step: nil,
    steps: [],
    percentage: nil,
    css_class: "progress-container",
    labels: true,
    show_bar: true,
    **html_options
  )
    @current_step = current_step&.to_s
    @steps = steps.map(&:to_s)
    @percentage = percentage
    @css_class = css_class
    @labels = labels
    @show_bar = show_bar
    @html_options = html_options
  end

  private

  attr_reader :current_step, :steps, :percentage, :css_class, :labels, :show_bar, :html_options

  def calculated_percentage
    return percentage if percentage

    return 0 if steps.empty?

    current_idx = steps.index(current_step)
    return 0 unless current_idx

    ((current_idx + 1).to_f / steps.length * 100).round
  end

  def step_classes(step)
    step = step.to_s
    return "step active" if step == current_step

    current_idx = steps.index(current_step)
    idx = steps.index(step)
    return "step" unless current_idx && idx

    idx < current_idx ? "step completed" : "step"
  end

  def final_html_options
    options = html_options.dup
    options[:class] = [css_class, options[:class]].compact.join(' ')
    options
  end

  def step_label(step)
    # Generic component should just humanize the step name
    # Subclasses can override this for domain-specific translations
    step.humanize
  end
end
