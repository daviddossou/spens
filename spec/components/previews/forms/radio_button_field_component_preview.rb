# frozen_string_literal: true

class Forms::RadioButtonFieldComponentPreview < ViewComponent::Preview
  # Basic radio button group
  # -------------------------
  # A simple group of radio buttons with labels
  def default
    render_with_template
  end

  # Checked state
  # -------------
  # Shows radio buttons with one pre-selected
  def with_checked
    render_with_template
  end

  # With help text
  # --------------
  # Radio buttons with helpful descriptions
  def with_help_text
    render_with_template
  end

  # Custom styling
  # --------------
  # Radio buttons with custom classes for wrapper, label, and input
  def with_custom_classes
    render_with_template
  end

  # Hidden labels (accessibility pattern)
  # --------------------------------------
  # Radio buttons without visible labels (label still present for screen readers)
  def with_hidden_labels
    render_with_template
  end

  # Content block labels
  # --------------------
  # Radio buttons with rich HTML content as labels
  def with_content_blocks
    render_with_template
  end

  # With errors
  # -----------
  # Shows error state with validation messages
  def with_errors
    render_with_template
  end

  # Compact inline layout
  # ---------------------
  # Radio buttons arranged horizontally with custom styling
  def inline_layout
    render_with_template
  end

  # Card-based selection
  # --------------------
  # Radio buttons styled as selectable cards (common pattern)
  def card_style
    render_with_template
  end
end
