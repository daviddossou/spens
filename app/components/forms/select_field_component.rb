# frozen_string_literal: true

class Forms::SelectFieldComponent < ViewComponent::Base
  def initialize(
    form:,
    field:,
    options:,
    label: nil,
    required: false,
    help_text: nil,
    include_blank: nil,
    priority_options: nil,
    searchable: false,
    wrapper_classes: nil,
    label_classes: nil,
    field_classes: nil,
    **field_options
  )
    @form = form
    @field = field
    @options = options
    @label = label
    @required = required
    @help_text = help_text
    @include_blank = include_blank
    @priority_options = priority_options
    @searchable = searchable
    @wrapper_classes = wrapper_classes
    @label_classes = label_classes
    @field_classes = field_classes
    @field_options = field_options
  end

  private

  attr_reader :form, :field, :options, :label, :required, :help_text, :include_blank,
              :priority_options, :searchable, :wrapper_classes, :label_classes, :field_classes, :field_options

  def field_label
    label || field.to_s.humanize
  end

  def default_wrapper_classes
    "form-field"
  end

  def default_label_classes
    "form-label"
  end

  def default_field_classes
    base_classes = "form-select"
    error_classes = has_errors? ? "form-select-error" : ""
    searchable_classes = searchable ? "searchable-select" : ""
    [ base_classes, error_classes, searchable_classes ].reject(&:blank?).join(" ")
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
    opts = field_options.dup

    if searchable
      opts[:data] ||= {}
      existing_controller = opts[:data][:controller]
      opts[:data][:controller] = if existing_controller.present?
        "#{existing_controller} searchable-select"
      else
        "searchable-select"
      end
    end

    opts
  end

  def has_errors?
    form.object.errors.key?(field)
  end

  def error_messages
    form.object.errors.full_messages_for(field)
  end

  def has_priority_options?
    priority_options.present? && priority_options.any?
  end

  def options_for_select
    convert_options_format(@options)
  end

  def priority_options_for_select
    return [] unless has_priority_options?
    convert_options_format(@priority_options)
  end

  def regular_options_for_select
    return options_for_select unless has_priority_options?

    priority_values = priority_options_for_select.map(&:last)
    options_for_select.reject { |opt| priority_values.include?(opt.last) }
  end

  def priority_and_regular_options
    priority_opts = priority_options_for_select
    regular_opts = regular_options_for_select

    result = []

    if include_blank
      blank_text = include_blank.is_a?(String) ? include_blank : ""
      result << [ blank_text, "" ]
    end

    result += priority_opts

    result << [ "───────────────", "___divider___", { disabled: true, class: "option-divider" } ]

    result += regular_opts

    result
  end

  def convert_options_format(opts)
    if opts.is_a?(Hash)
      opts.map { |key, value| [ value, key ] }
    elsif opts.first.is_a?(Array)
      opts
    else
      opts.map { |opt| [ opt, opt ] }
    end
  end
end
