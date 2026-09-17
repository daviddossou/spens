# frozen_string_literal: true

class Forms::ErrorsComponent < ViewComponent::Base
  def initialize(object:, detailed: false)
    @object = object
    @detailed = detailed
  end

  private

  attr_reader :object, :detailed
end
