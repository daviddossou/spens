# frozen_string_literal: true

class Marketing::FooterComponent < ViewComponent::Base
  def initialize(classes:, links_class: nil)
    @classes = classes
    @links_class = links_class
  end

  private

  attr_reader :classes, :links_class
end
