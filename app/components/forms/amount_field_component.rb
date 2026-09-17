# frozen_string_literal: true

# The amount hero every money form opens with: one big numeric field, the
# currency beside it, an optional period label under it. Works with a form
# builder or a bare name (the monthly envelope editor posts without a model).
class Forms::AmountFieldComponent < ViewComponent::Base
  renders_one :period

  def initialize(currency:, aria_label:, form: nil, field: nil, name: nil, value: nil,
                 min: "0.01", placeholder: "0", autofocus: false, required: false,
                 data: {}, classes: nil)
    @currency = currency
    @aria_label = aria_label
    @form = form
    @field = field
    @name = name
    @value = value
    @min = min
    @placeholder = placeholder
    @autofocus = autofocus
    @required = required
    @data = data
    @classes = classes
  end

  private

  attr_reader :currency, :aria_label, :form, :field, :name, :min, :placeholder,
              :autofocus, :required, :data, :classes

  def root_classes
    [ "budget-amount", classes ].compact.join(" ")
  end

  # A whole number is typed without ".0"; a decimal keeps its cents.
  def display_value
    return nil if @value.blank?

    @value % 1 == 0 ? @value.to_i : @value.to_f
  end

  def input_options
    {
      class: "budget-amount__input", value: display_value,
      step: "0.01", min: min, inputmode: "decimal", placeholder: placeholder,
      autofocus: autofocus, required: required,
      aria: { label: aria_label }, data: data
    }
  end

  def render_input
    if form
      form.number_field(field, input_options)
    else
      number_field_tag(name || field, display_value, input_options.except(:value))
    end
  end
end
