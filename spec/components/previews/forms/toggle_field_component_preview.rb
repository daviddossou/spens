# frozen_string_literal: true

module Forms
  # @label Toggle Field
  class ToggleFieldComponentPreview < ViewComponent::Preview
    # Unchecked
    def default
      render(Forms::ToggleFieldComponent.new(name: "budget_item[rollover]", checked: false, label: "Carry the rest over"))
    end

    # Checked with a hint slot for the live example
    def checked_with_hint
      render(Forms::ToggleFieldComponent.new(
        name: "budget_item[rollover]", checked: true, label: "Carry the rest over",
        hint_data: { budget_line_target: "rolloverExample" }, data: { budget_line_target: "rollover" }
      ))
    end
  end
end
