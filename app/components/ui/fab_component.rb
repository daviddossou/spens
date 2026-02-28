# frozen_string_literal: true

class Ui::FabComponent < ViewComponent::Base
  def initialize(url:, label: nil)
    @url = url
    @label = label
  end

  private

  attr_reader :url, :label
end
