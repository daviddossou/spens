# frozen_string_literal: true

class Ui::PageHeaderComponent < ViewComponent::Base
  def initialize(classes: nil)
    @classes = classes
  end

  private

  attr_reader :classes
end
