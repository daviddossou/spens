# frozen_string_literal: true

class Ui::EmptyStateComponent < ViewComponent::Base
  def initialize(classes: "empty-state")
    @classes = classes
  end

  private

  attr_reader :classes
end
