# frozen_string_literal: true

class Ui::SelectableCardComponentPreview < ViewComponent::Preview
  include ActionView::Helpers::FormHelper
  include ActionView::Context

  # Simple hash item
  def default
    render_with_template locals: {}
  end

  # Selected state
  def selected_card
    render_with_template locals: {}
  end

  # With custom CSS class
  def custom_styling
    render_with_template locals: {}
  end

  # Without description
  def no_description
    render_with_template locals: {}
  end

  # With data attributes for Stimulus
  def with_stimulus
    render_with_template locals: {}
  end

  # String-based item (edge case)
  def string_item
    render_with_template locals: {}
  end

  # Object-like item with methods
  def object_item
    render_with_template locals: {}
  end

  # Multiple cards (grid layout)
  def cards_grid
    render_with_template locals: {}
  end

  # With form integration (real form for preview)
  def with_form_integration
    render_with_template locals: {}
  end

  # Value sources test
  def values_test
    render_with_template locals: {}
  end

  # Long content example
  def long_content
    render_with_template locals: {}
  end

  # Visual checkbox - unselected state
  def visual_checkbox_unselected
    render_with_template locals: {}
  end

  # Visual checkbox - selected state
  def visual_checkbox_selected
    render_with_template locals: {}
  end

  # Visual checkbox hidden
  def visual_checkbox_hidden
    render_with_template locals: {}
  end

  # Comparison grid - with and without visual checkbox
  # This method uses a custom template to show both variations side by side
  def visual_checkbox_comparison
    render_with_template locals: {}
  end

  # Compact mode - single selection (radio buttons)
  def compact_single_selection
    render_with_template locals: {}
  end

  # Compact mode - multiple selection (checkboxes)
  def compact_multiple_selection
    render_with_template locals: {}
  end

  # Compact vs Normal comparison
  def compact_comparison
    render_with_template locals: {}
  end

  # Radio button mode - transaction kind selector
  def radio_button_mode
    render_with_template locals: {}
  end

  # Additional classes example
  def with_additional_classes
    render_with_template locals: {}
  end

  # Real-world example: Transaction form kind selector
  def transaction_kind_selector
    render_with_template locals: {}
  end

  # Link mode - cards as pure visual elements
  def link_mode
    render_with_template locals: {}
  end
end
