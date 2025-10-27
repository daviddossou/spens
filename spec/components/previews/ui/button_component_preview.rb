# frozen_string_literal: true

class Ui::ButtonComponentPreview < ViewComponent::Preview
  def default(text: "Click me", variant: :primary, size: :md)
    render Ui::ButtonComponent.new(
      text: text,
      variant: variant.to_sym,
      size: size.to_sym
    )
  end

  def all_variants
    variants = [
      :primary, :secondary, :danger, :success, :warning,
      :"outline-primary", :"outline-secondary", :"outline-danger",
      :"outline-success", :"outline-warning"
    ]

    render_with_template locals: { variants: variants }
  end

  def sizes
    sizes = [ :xs, :sm, :md, :lg, :xl ]

    render_with_template locals: { sizes: sizes }
  end

  def loading
    render Ui::ButtonComponent.new(
      text: "Loading...",
      loading: true,
      variant: :primary
    )
  end

  def disabled
    render Ui::ButtonComponent.new(
      text: "Disabled",
      disabled: true,
      variant: :primary
    )
  end

  def link_button
    render Ui::ButtonComponent.new(
      text: "Link Button",
      url: "#",
      variant: :primary
    )
  end

  def with_content_block
    render_with_template
  end

  def full_width
    render_with_template
  end

  def with_icons
    render_with_template
  end

  def with_turbo_method
    render_with_template
  end

  def submit_button_in_form
    render_with_template
  end

  def with_data_attributes
    render_with_template
  end

  def combined_states
    render_with_template
  end
end
