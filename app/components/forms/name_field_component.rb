# frozen_string_literal: true

# A naming field (Tour 30d): the user invents a word the app cannot know, so the
# keyboard is legitimate here. The suggestion is therefore a single row of chips
# glued under the field — 40px no keyboard can cover — never a vertical list.
class Forms::NameFieldComponent < ViewComponent::Base
  def initialize(form:, field:, label:, placeholder:, suggestions: [], see_all_title: nil, field_data: {})
    @form = form
    @field = field
    @label = label
    @placeholder = placeholder
    @suggestions = suggestions
    @see_all_title = see_all_title
    @field_data = field_data
  end

  private

  attr_reader :form, :field, :label, :placeholder, :suggestions, :see_all_title, :field_data

  # Stimulus actions concatenate; merging the hash would drop ours for the
  # caller's, so the chips would stop filtering as you type.
  def input_data
    data = { name_chips_target: "input" }.merge(field_data)
    data[:action] = [ "input->name-chips#render", field_data[:action] ].compact.join(" ")
    data
  end
end
