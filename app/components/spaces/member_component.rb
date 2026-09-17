# frozen_string_literal: true

class Spaces::MemberComponent < ViewComponent::Base
  def initialize(space:, member:, full_name:)
    @space = space
    @member = member
    @full_name = full_name
  end

  private

  attr_reader :space, :member, :full_name
end
