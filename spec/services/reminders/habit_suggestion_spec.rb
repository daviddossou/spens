# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reminders::HabitSuggestion do
  let(:user) { create(:user, time_zone: 'Africa/Porto-Novo') }
  let(:space) { user.spaces.first }
  let(:membership) { user.memberships.find_by(space: space) }

  before { travel_to Time.utc(2026, 9, 21, 9) }

  # hour is on the member clock (UTC+1)
  def note(days_ago:, hour:, minute: 5)
    time = Time.find_zone('Africa/Porto-Novo').local(2026, 9, 21, hour, minute) - days_ago.days
    create(:transaction, space: space).update_columns(user_id: user.id, created_at: time)
  end

  it 'finds the hour a member usually notes at, neighbouring hours together' do
    note(days_ago: 1, hour: 13)
    note(days_ago: 2, hour: 12, minute: 50)
    note(days_ago: 3, hour: 13)
    note(days_ago: 5, hour: 13)
    note(days_ago: 6, hour: 8)

    expect(described_class.new(membership).hour).to eq(13)
  end

  it 'suggests nothing without a clear habit' do
    [ 7, 11, 15, 19, 22 ].each_with_index { |hour, index| note(days_ago: index + 1, hour: hour) }

    expect(described_class.new(membership).hour).to be_nil
  end

  it 'suggests nothing from too few days' do
    3.times { |index| note(days_ago: index + 1, hour: 13) }

    expect(described_class.new(membership).hour).to be_nil
  end

  it 'suggests nothing to someone who has a reminder or said no' do
    5.times { |index| note(days_ago: index + 1, hour: 13) }

    membership.update!(reminder_enabled: true)
    expect(described_class.new(membership).hour).to be_nil

    membership.update!(reminder_enabled: false, reminder_declined_at: Time.current)
    expect(described_class.new(membership).hour).to be_nil
  end
end
