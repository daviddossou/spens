# frozen_string_literal: true

module Forms
  # @label Segmented Choice
  class SegmentedChoiceComponentPreview < ViewComponent::Preview
    # Deadline pills, one selected
    def default
      render(Forms::SegmentedChoiceComponent.new(
        options: [
          { label: "6 months", data: { deadline_mode: "m6" } },
          { label: "1 year", selected: true, data: { deadline_mode: "y1" } },
          { label: "A date", data: { deadline_mode: "other" } },
          { label: "None", data: { deadline_mode: "none" } }
        ],
        data: { action: "goal-form#setDeadline" }
      ))
    end

    # Three equal pills, none selected
    def three_columns
      render(Forms::SegmentedChoiceComponent.new(
        classes: "pill-choice pill-choice--three",
        options: [ { label: "End of month" }, { label: "In 3 months" }, { label: "Other" } ]
      ))
    end

    # Frequency segments with custom classes
    def custom_classes
      render(Forms::SegmentedChoiceComponent.new(
        classes: "seg-group", button_class: "seg", active_class: "seg--active",
        options: [ { label: "Monthly", selected: true }, { label: "Quarterly" }, { label: "Yearly" } ]
      ))
    end
  end
end
