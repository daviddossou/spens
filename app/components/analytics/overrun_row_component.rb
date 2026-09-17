# frozen_string_literal: true

class Analytics::OverrunRowComponent < ViewComponent::Base
  def initialize(row:)
    @row = row
  end

  private

  attr_reader :row

  delegate :money, to: :helpers
end
