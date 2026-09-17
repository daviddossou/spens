# frozen_string_literal: true

module Forms
  # @label Amount Field
  class AmountFieldComponentPreview < ViewComponent::Preview
    # Through a form builder, with a period label
    def default
      render_with_template
    end

    # Bare named input (no model), as the monthly envelope editor posts it
    def bare
      render(Forms::AmountFieldComponent.new(name: :amount, value: 50_000, currency: "FCFA", aria_label: "Amount", required: true))
    end

    # Empty, autofocused, with a decimal placeholder
    def empty
      render(Forms::AmountFieldComponent.new(name: :amount, currency: "€", aria_label: "Amount", placeholder: "0.00", autofocus: true))
    end
  end
end
