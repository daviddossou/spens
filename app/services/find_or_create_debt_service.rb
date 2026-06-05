# frozen_string_literal: true

class FindOrCreateDebtService
  def initialize(space, name, direction, user = nil)
    @space = space
    @name = name
    @direction = direction
    @user = user
  end

  def call
    existing = @space.debts
                     .where(direction: @direction)
                     .where("lower(name) = ?", @name.to_s.strip.downcase)
                     .first
    return existing if existing

    @space.debts.create!(
      name: @name.strip,
      direction: @direction,
      status: :ongoing,
      user: @user
    )
  end
end
