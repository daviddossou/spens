# frozen_string_literal: true

class Ui::SelectableCardComponentPreview < ViewComponent::Preview
  # Simple hash item
  def default
    render Ui::SelectableCardComponent.new(
      item: {
        name: "Basic Option",
        description: "This is a basic selectable card option",
        key: "basic"
      },
      selected: false
    )
  end

  # Selected state
  def selected_card
    render Ui::SelectableCardComponent.new(
      item: {
        name: "Selected Option",
        description: "This card is currently selected",
        key: "selected"
      },
      selected: true
    )
  end

  # With custom CSS class
  def custom_styling
    render Ui::SelectableCardComponent.new(
      item: {
        name: "Custom Styled Card",
        description: "This card has custom CSS classes",
        key: "custom"
      },
      css_class: "premium-card",
      description_classes: "text-sm text-gray-600"
    )
  end

  # Without description
  def no_description
    render Ui::SelectableCardComponent.new(
      item: {
        name: "Simple Card",
        key: "simple"
      },
      selected: false
    )
  end

  # With data attributes for Stimulus
  def with_stimulus
    render Ui::SelectableCardComponent.new(
      item: {
        name: "Interactive Card",
        description: "This card has Stimulus data attributes",
        key: "interactive"
      },
      data: {
        'controller-target': 'card',
        action: 'click->controller#toggle',
        value: 'interactive-option'
      }
    )
  end

  # String-based item (edge case)
  def string_item
    render Ui::SelectableCardComponent.new(
      item: "Simple String Option",
      selected: false
    )
  end

  # Object-like item with methods
  def object_item
    item = OpenStruct.new(
      name: "Object Item",
      description: "This item uses method access",
      id: 123
    )

    render Ui::SelectableCardComponent.new(
      item: item,
      selected: true
    )
  end

  # Multiple cards (grid layout)
  def cards_grid
    render Ui::SelectableCardComponent.new(
      item: { name: "Option A", description: "First option", key: "a" },
      selected: false
    )
  end

  # With form integration (mock form for preview)
  def with_form_integration
    # Create mock errors object
    mock_errors = Class.new do
      def key?(field)
        false # No errors for preview
      end
    end

    # Create mock object and form builder class
    mock_object = OpenStruct.new(errors: mock_errors.new)

    mock_form_class = Class.new do
      def initialize(object)
        @object = object
      end

      attr_reader :object

      def check_box(*args)
        field = args[0]
        options = args[1] || {}
        value = args[2]

        checked_attr = options[:checked] ? 'checked' : ''
        value_attr = value ? "value='#{value}'" : ''
        "<input type='checkbox' name='#{field}[]' #{value_attr} #{checked_attr} style='display: none;' />".html_safe
      end
    end

    render Ui::SelectableCardComponent.new(
      item: {
        name: "Form Integrated Card",
        description: "This card integrates with a form (checkbox hidden)",
        key: "form-card"
      },
      form: mock_form_class.new(mock_object),
      field: :preferences,
      selected: true
    )
  end

  # Value sources test
  def values_test
    render Ui::SelectableCardComponent.new(
      item: { name: "Test", key: "test" },
      selected: false
    )
  end

  # Long content example
  def long_content
    render Ui::SelectableCardComponent.new(
      item: {
        name: "Card with Long Content",
        description: "This is a demonstration of how the selectable card component handles longer descriptions and content. It should wrap appropriately and maintain good readability even with extensive text content that spans multiple lines.",
        key: "long-content"
      },
      selected: false,
      description_classes: "text-sm leading-relaxed"
    )
  end

  # Visual checkbox - unselected state
  def visual_checkbox_unselected
    render Ui::SelectableCardComponent.new(
      item: {
        name: "Unselected Card",
        description: "This card is unselected - no visual checkbox should be visible",
        key: "unselected"
      },
      selected: false,
      show_visual_checkbox: true
    )
  end

  # Visual checkbox - selected state
  def visual_checkbox_selected
    render Ui::SelectableCardComponent.new(
      item: {
        name: "Selected Card",
        description: "This card shows the visual checkbox in selected state with checkmark",
        key: "selected"
      },
      selected: true,
      show_visual_checkbox: true
    )
  end

  # Visual checkbox hidden
  def visual_checkbox_hidden
    render Ui::SelectableCardComponent.new(
      item: {
        name: "No Visual Checkbox",
        description: "This card has the visual checkbox disabled",
        key: "no-checkbox"
      },
      selected: true,
      show_visual_checkbox: false
    )
  end

  # Comparison grid - with and without visual checkbox
  # This method uses a custom template to show both variations side by side
  def visual_checkbox_comparison
  end
end
