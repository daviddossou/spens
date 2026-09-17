# frozen_string_literal: true

class Transactions::KindSelectorComponent < ViewComponent::Base
  def initialize(options:, label:, data: {})
    @options = options
    @label = label
    @data = data
  end

  private

  attr_reader :options, :label, :data

  delegate :transaction_icon_svg, to: :helpers
end
