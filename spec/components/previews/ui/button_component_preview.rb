# frozen_string_literal: true

class Ui::ButtonComponentPreview < ViewComponent::Preview
  # Default button
  # @param text text
  # @param variant select { choices: [primary, secondary, danger, success, warning, outline] }
  # @param size select { choices: [xs, sm, md, lg, xl] }
  def default(text: "Click me", variant: :primary, size: :md)
    render Ui::ButtonComponent.new(
      text: text,
      variant: variant.to_sym,
      size: size.to_sym
    )
  end

  # All variants
  def all_variants
    variants = [ :primary, :secondary, :danger, :success, :warning, :outline ]

    render_with_template locals: { variants: variants }
  end

  # Different sizes
  def sizes
    sizes = [ :xs, :sm, :md, :lg, :xl ]

    render_with_template locals: { sizes: sizes }
  end

  # Loading states
  def loading
    render Ui::ButtonComponent.new(
      text: "Loading...",
      loading: true,
      variant: :primary
    )
  end

  # Disabled state
  def disabled
    render Ui::ButtonComponent.new(
      text: "Disabled",
      disabled: true,
      variant: :primary
    )
  end

  # Link button
  def link_button
    render Ui::ButtonComponent.new(
      text: "Link Button",
      url: "#",
      variant: :primary
    )
  end
end
