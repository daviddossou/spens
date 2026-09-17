# frozen_string_literal: true

class Forms::ToggleFieldComponent < ViewComponent::Base
  def initialize(name:, checked:, label:, hint_data: nil, data: {})
    @name = name
    @checked = checked
    @label = label
    @hint_data = hint_data
    @data = data
  end

  private

  attr_reader :name, :checked, :label, :hint_data, :data
end
