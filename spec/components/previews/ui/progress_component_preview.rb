# frozen_string_literal: true

class Ui::ProgressComponentPreview < ViewComponent::Preview
  # Basic progress bar with percentage
  def default
    render Ui::ProgressComponent.new(
      percentage: 65,
      css_class: "w-full max-w-md mx-auto"
    )
  end

  # Step-based progress with labels
  def with_steps
    render Ui::ProgressComponent.new(
      current_step: "step_2",
      steps: [ "step_1", "step_2", "step_3", "step_4" ],
      css_class: "w-full max-w-lg mx-auto"
    )
  end

  # Progress bar only (no labels)
  def bar_only
    render Ui::ProgressComponent.new(
      current_step: "processing",
      steps: [ "pending", "processing", "completed" ],
      labels: false,
      css_class: "w-full max-w-sm mx-auto"
    )
  end

  # Labels only (no progress bar)
  def labels_only
    render Ui::ProgressComponent.new(
      current_step: "review",
      steps: [ "draft", "review", "approved", "published" ],
      show_bar: false,
      css_class: "flex justify-between w-full max-w-md mx-auto"
    )
  end

  # Custom percentage override
  def custom_percentage
    render Ui::ProgressComponent.new(
      current_step: "middle",
      steps: [ "start", "middle", "end" ],
      percentage: 85, # Override calculated percentage
      css_class: "w-full max-w-md mx-auto"
    )
  end

  # Empty state (no current step)
  def empty_state
    render Ui::ProgressComponent.new(
      steps: [ "todo", "in_progress", "done" ],
      css_class: "w-full max-w-md mx-auto"
    )
  end

  # Single step (edge case)
  def single_step
    render Ui::ProgressComponent.new(
      current_step: "complete",
      steps: [ "complete" ],
      css_class: "w-full max-w-md mx-auto"
    )
  end

  # Workflow example
  def workflow_example
    render Ui::ProgressComponent.new(
      current_step: "testing",
      steps: [ "planning", "development", "testing", "deployment", "monitoring" ],
      css_class: "w-full max-w-2xl mx-auto p-4 border rounded"
    )
  end
end
