# frozen_string_literal: true

class Marketing::GuideDownloadComponent < ViewComponent::Base
  def initialize(url:, filename:, label:, placement:, classes:)
    @url = url
    @filename = filename
    @label = label
    @placement = placement
    @classes = classes
  end

  private

  attr_reader :url, :filename, :label, :placement, :classes
end
