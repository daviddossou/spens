# frozen_string_literal: true

class FormFieldComponent < ViewComponent::Base
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
    "space-y-1"
  end

  def default_label_classes
    "block text-sm font-medium"
  end

  def default_field_classes
    "appearance-none block w-full px-3 py-2 border border-slate-gray rounded-md placeholder-gray-400 focus:outline-none focus:ring-secondary focus:border-steel-blue sm:text-sm"
  end

  def final_wrapper_classes
    [default_wrapper_classes, wrapper_classes].compact.join(" ")
  end

  def final_label_classes
    [default_label_classes, label_classes].compact.join(" ")
  end

  def final_field_classes
    [default_field_classes, field_classes].compact.join(" ")
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

  def error_classes
    "text-sm text-red-600 mt-1"
  end
end
