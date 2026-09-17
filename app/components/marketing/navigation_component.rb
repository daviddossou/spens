# frozen_string_literal: true

class Marketing::NavigationComponent < ViewComponent::Base
  def initialize(guide: false)
    @guide = guide
  end

  private

  attr_reader :guide
end
