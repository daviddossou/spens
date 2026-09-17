# frozen_string_literal: true

class Spaces::MappingRowComponent < ViewComponent::Base
  def initialize(space:, mapping:, keyword: false)
    @space = space
    @mapping = mapping
    @keyword = keyword
  end

  private

  attr_reader :space, :mapping, :keyword

  delegate :taxonomy_grouped_options, to: :helpers
end
