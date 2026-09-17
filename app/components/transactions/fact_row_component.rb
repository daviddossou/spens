# frozen_string_literal: true

class Transactions::FactRowComponent < ViewComponent::Base
  def initialize(label:, value:, url: nil, frame: "modal")
    @label = label
    @value = value
    @url = url
    @frame = frame
  end

  private

  attr_reader :label, :value, :url, :frame
end
