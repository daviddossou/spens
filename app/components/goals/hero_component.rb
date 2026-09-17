# frozen_string_literal: true

class Goals::HeroComponent < ViewComponent::Base
  def initialize(account:, progress:)
    @account = account
    @progress = progress
  end

  private

  attr_reader :account, :progress

  delegate :goal_hero_meta, :money, to: :helpers
end
