# frozen_string_literal: true

class Analytics::AccountDistributionComponent < ViewComponent::Base
  def initialize(accounts:)
    @accounts = accounts
  end

  private

  attr_reader :accounts

  delegate :money, to: :helpers
end
