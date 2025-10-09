# frozen_string_literal: true

class Forms::CheckboxFieldComponent < ViewComponent::Base
  def initialize(
    form:,
    field:,
    label: nil,
    help_text: nil,
    wrapper_classes: nil,
    label_classes: nil,
    checkbox_classes: nil,
    **field_options
  )
    @form = form
    @field = field
    @label = label
    @help_text = help_text
    @wrapper_classes = wrapper_classes
    @label_classes = label_classes
    @checkbox_classes = checkbox_classes
    @field_options = field_options
  end

  private

  attr_reader :form, :field, :label, :help_text,
              :wrapper_classes, :label_classes, :checkbox_classes, :field_options

  def field_label
    label || t(".#{field}", default: field.to_s.humanize)
  end

  def default_wrapper_classes
    "flex items-center"
  end

  def default_checkbox_classes
    "h-4 w-4 text-primary focus:ring-secondary border-gray-300 rounded"
  end

  def default_label_classes
    "ml-2 block text-sm text-gray-900"
  end

  def final_wrapper_classes
    [default_wrapper_classes, wrapper_classes].compact.join(" ")
  end

  def final_label_classes
    [default_label_classes, label_classes].compact.join(" ")
  end

  def final_checkbox_classes
    [default_checkbox_classes, checkbox_classes].compact.join(" ")
  end

  def final_field_options
    field_options.merge(class: final_checkbox_classes)
  end

  def has_errors?
    form.object&.errors&.key?(field)
  end

  def field_errors
    form.object&.errors&.full_messages_for(field) || []
  end

  def error_classes
    "text-sm text-red-600 mt-1"
  end
end
