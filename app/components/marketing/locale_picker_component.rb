# frozen_string_literal: true

class Marketing::LocalePickerComponent < ViewComponent::Base
  def initialize(countries:)
    @countries = countries
  end

  private

  attr_reader :countries
end
