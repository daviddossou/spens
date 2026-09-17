# frozen_string_literal: true

class Spaces::CardComponent < ViewComponent::Base
  def initialize(space:, active:)
    @space = space
    @active = active
  end

  private

  attr_reader :space, :active
end
