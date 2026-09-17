# frozen_string_literal: true

class Transactions::SearchComponent < ViewComponent::Base
  def initialize(query:)
    @query = query
  end

  private

  attr_reader :query
end
