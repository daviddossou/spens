# frozen_string_literal: true

class Analytics::SpendingSplitBarComponent < ViewComponent::Base
  def initialize(split:, total:)
    @split = split
    @total = total
  end

  private

  attr_reader :split, :total
end
