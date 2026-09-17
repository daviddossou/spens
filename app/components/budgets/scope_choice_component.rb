# frozen_string_literal: true

class Budgets::ScopeChoiceComponent < ViewComponent::Base
  def initialize(month_name:, month_prep:)
    @month_name = month_name
    @month_prep = month_prep
  end

  private

  attr_reader :month_name, :month_prep
end
