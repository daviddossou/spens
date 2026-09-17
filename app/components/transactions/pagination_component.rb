# frozen_string_literal: true

class Transactions::PaginationComponent < ViewComponent::Base
  def initialize(has_more:)
    @has_more = has_more
  end

  private

  attr_reader :has_more
end
