# frozen_string_literal: true

class Marketing::FeatureCardComponent < ViewComponent::Base
  def initialize(card:, i:, feature_shots:)
    @card = card
    @i = i
    @feature_shots = feature_shots
  end

  private

  attr_reader :card, :i, :feature_shots
end
