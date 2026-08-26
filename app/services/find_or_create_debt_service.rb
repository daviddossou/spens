# frozen_string_literal: true

class FindOrCreateDebtService
  def initialize(space, name, direction, user = nil)
    @space = space
    @name = name
    @direction = direction
    @user = user
  end

  def call
    # Match only an OPEN debt — a written-off/settled one is history, so a new
    # loan to the same person starts a fresh debt rather than reviving the old.
    existing = @space.debts.ongoing
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
