# frozen_string_literal: true

# Spots a member who usually records at the same time of day, so the dashboard can offer a
# reminder at that hour. Nothing is suggested to someone who has a reminder, or said no.
class Reminders::HabitSuggestion
  WINDOW = 14.days
  MIN_DAYS = 4      # distinct days with an entry around that hour
  MIN_SHARE = 0.6   # of all the days they recorded on

  def initialize(membership)
    @membership = membership
  end

  # The usual hour (0..23), or nil.
  def hour
    return if @membership.reminder_enabled? || @membership.reminder_declined_at?

    days_by_hour = recorded_at.group_by(&:hour).transform_values { |times| times.map(&:to_date).uniq }
    active_days = days_by_hour.values.flatten.uniq.size
    return if active_days < MIN_DAYS

    # An hour and its neighbour count together (12:50 and 13:10 are one habit); the busier of
    # the two is the hour suggested.
    days_at = ->(h) { days_by_hour.fetch(h % 24, []) }
    start, days = (0..23).map { |h| [ h, (days_at[h] | days_at[h + 1]).size ] }.max_by(&:last)
    return unless days >= MIN_DAYS && days >= active_days * MIN_SHARE

    days_at[start + 1].size > days_at[start].size ? (start + 1) % 24 : start
  end

  private

  def recorded_at
    zone = @membership.time_zone
    @membership.space.transactions.joins(:transaction_type)
               .where(user: @membership.user, created_at: WINDOW.ago..)
               .where.not(transaction_types: { kind: %w[initial_balance adjustment] })
               .pluck(:created_at).map { |time| time.in_time_zone(zone) }
  end
end
