# frozen_string_literal: true

# A choice field (Tour 31): a tappable row, never a text input, so it summons no
# keyboard. The value it submits is the same NAME the forms already posted, so
# creation by name on submit keeps working untouched.
class Forms::PickerFieldComponent < ViewComponent::Base
  def initialize(form:, field:, rows:, label:, placeholder:, title: nil, help_text: nil,
                 allow_create: false, grouped: false, empty_label: nil,
                 id: nil, chain_to: nil, chain_reason: nil, field_data: {})
    @form = form
    @field = field
    @rows = rows
    @label = label
    @placeholder = placeholder
    @title = title || label
    @help_text = help_text
    @allow_create = allow_create
    @grouped = grouped
    @empty_label = empty_label
    @id = id
    @chain_to = chain_to
    @chain_reason = chain_reason
    @field_data = field_data
  end

  private

  attr_reader :form, :field, :rows, :label, :placeholder, :title, :help_text,
              :allow_create, :grouped, :empty_label, :id, :chain_to, :chain_reason, :field_data

  def current_value
    form.object.public_send(field).to_s
  end

  # A stored value that is not in the list (an archived account, a category
  # renamed since) still has to read as the answer it is.
  def display_label
    return placeholder if current_value.blank?

    row = rows.find { |r| r[:value] == current_value }
    row ? row[:label] : current_value
  end

  def value_classes
    [ "picker__value", ("picker__value--empty" if current_value.blank?) ].compact.join(" ")
  end

  def controller_data
    {
      controller: "picker",
      picker_title_value: title,
      picker_rows_value: rows.to_json,
      picker_allow_create_value: allow_create,
      picker_placeholder_value: placeholder,
      picker_grouped_value: grouped
    }.tap do |data|
      data[:picker_empty_label_value] = empty_label if empty_label.present?
      data[:picker_chain_to_value] = chain_to if chain_to.present?
      data[:picker_chain_reason_value] = chain_reason if chain_reason.present?
    end
  end
end
