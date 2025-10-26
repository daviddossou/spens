# frozen_string_literal: true

class Forms::InputFieldComponent < ViewComponent::Base
  def initialize(
    form:,
    field:,
    type: :text_field,
    label: nil,
    required: false,
    help_text: nil,
    wrapper_classes: nil,
    label_classes: nil,
    field_classes: nil,
    **field_options
  )
    @form = form
    @field = field
    @type = type
    @label = label
    @required = required
    @help_text = help_text
    @wrapper_classes = wrapper_classes
    @label_classes = label_classes
    @field_classes = field_classes
    @field_options = field_options
  end

  private

  attr_reader :form, :field, :type, :label, :required, :help_text,
              :wrapper_classes, :label_classes, :field_classes, :field_options

  def field_label
    label || t(".#{field}", default: field.to_s.humanize)
  end

  def default_wrapper_classes
    "form-field"
  end

  def default_label_classes
    "form-label"
  end

  def default_field_classes
    base_classes = "form-input"
    error_classes = has_errors? ? "form-input-error" : ""
    [ base_classes, error_classes ].compact.join(" ")
  end

  def final_wrapper_classes
    [ default_wrapper_classes, wrapper_classes ].compact.join(" ")
  end

  def final_label_classes
    [ default_label_classes, label_classes ].compact.join(" ")
  end

  def final_field_classes
    [ default_field_classes, field_classes ].compact.join(" ")
  end

  def final_field_options
    field_options.merge(class: final_field_classes)
  end

  def has_errors?
    form.object&.errors&.key?(field)
  end

  def field_errors
    form.object&.errors&.full_messages_for(field) || []
  end
end
