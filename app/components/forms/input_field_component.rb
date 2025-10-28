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
    autocomplete: false,
    autocomplete_options: [],
    allow_create: false,
    prepend: nil,
    append: nil,
    name: nil,
    id: nil,
    value: nil,
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
    @autocomplete = autocomplete
    @autocomplete_options = autocomplete_options
    @allow_create = allow_create
    @prepend = prepend
    @append = append
    @custom_name = name
    @custom_id = id
    @custom_value = value
    @field_options = field_options
  end

  private

  attr_reader :form, :field, :type, :label, :required, :help_text,
              :wrapper_classes, :label_classes, :field_classes, :field_options,
              :autocomplete, :autocomplete_options, :allow_create,
              :prepend, :append,
              :custom_name, :custom_id, :custom_value

  def use_autocomplete?
    autocomplete && (autocomplete_options.any? || field_options[:url].present?)
  end

  def has_addon?
    prepend.present? || append.present?
  end

  def tom_select_data
    return {} unless use_autocomplete?

    data = {
      controller: "tom-select",
      tom_select_allow_create_value: allow_create,
      tom_select_placeholder_value: field_options[:placeholder] || field_label
    }

    if autocomplete_options.any?
      data[:tom_select_suggestions_value] = autocomplete_options.to_json
    end

    if field_options[:url].present?
      data[:tom_select_url_value] = field_options[:url]
    end

    if field_options[:tom_select_options].present?
      data[:tom_select_options_value] = field_options[:tom_select_options].to_json
    end

    data
  end

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
    base_classes = use_autocomplete? ? "form-input form-input-autocomplete" : "form-input"
    error_classes = has_errors? ? "form-input-error" : ""
    [ base_classes, error_classes ].compact.reject(&:empty?).join(" ")
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
    options = field_options.dup
    options[:class] = final_field_classes

    if use_autocomplete?
      options[:data] ||= {}
      options[:data].merge!(tom_select_data)

      options.delete(:placeholder)
    end

    options
  end

  def has_errors?
    form.object&.errors&.key?(field)
  end

  def field_errors
    form.object&.errors&.full_messages_for(field) || []
  end

  def autocomplete_options_for_select
    return [] unless use_autocomplete? && autocomplete_options.any?

    if autocomplete_options.first.is_a?(Array)
      autocomplete_options
    elsif autocomplete_options.first.is_a?(Hash)
      autocomplete_options.map { |opt| [ opt[:label] || opt[:text], opt[:value] || opt[:id] ] }
    else
      autocomplete_options.map { |opt| [ opt, opt ] }
    end
  end
end
