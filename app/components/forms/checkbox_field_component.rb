# frozen_string_literal: true

class Forms::CheckboxFieldComponent < ViewComponent::Base
  def initialize(
    form:,
    field:,
    label: nil,
    value: nil,
    multiple: false,
    checked: nil,
    help_text: nil,
    wrapper_classes: nil,
    label_classes: nil,
    checkbox_classes: nil,
    wrapper_data: {},
    hide_label: false,
    **field_options
  )
    @form = form
    @field = field
    @label = label
    @value = value
    @multiple = multiple
    @checked = checked
    @help_text = help_text
    @wrapper_classes = wrapper_classes
    @label_classes = label_classes
    @checkbox_classes = checkbox_classes
    @wrapper_data = wrapper_data
    @hide_label = hide_label
    @field_options = field_options
  end

  private

  attr_reader :form, :field, :label, :value, :multiple, :checked, :help_text,
              :wrapper_classes, :label_classes, :checkbox_classes, :wrapper_data,
              :hide_label, :field_options

  def field_label
    label || t(".#{field}", default: field.to_s.humanize)
  end

  def default_wrapper_classes
    base_classes = "checkbox-field"
    base_classes += " has-errors" if has_errors?
    base_classes
  end

  def final_wrapper_classes
    [ default_wrapper_classes, wrapper_classes ].compact.join(" ")
  end

  def final_field_options
    opts = field_options.dup
    opts[:class] = [ checkbox_classes, field_options[:class] ].compact.join(" ")
    opts[:multiple] = true if multiple
    opts
  end

  def render_checkbox
    if multiple
      form.check_box field, final_field_options.merge(checked: checked), value, nil
    else
      form.check_box field, final_field_options
    end
  end

  def has_errors?
    form.object&.errors&.key?(field)
  end

  def field_errors
    form.object&.errors&.full_messages_for(field) || []
  end

  def error_classes
    "error-text"
  end

  def wrapper_html_options
    opts = { class: final_wrapper_classes }
    opts[:data] = wrapper_data if wrapper_data.present?
    opts
  end
end
