# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reminders::DispatchJob do
  it 'delivers to reminding members only, and survives one failing' do
    on, failing, off = Array.new(3) { create(:user).memberships.first }
    [ on, failing ].each { |membership| membership.update!(reminder_enabled: true) }

    delivered = []
    allow(Reminders::DailyReminder).to receive(:new) do |membership|
      instance_double(Reminders::DailyReminder).tap do |reminder|
        allow(reminder).to receive(:deliver) do
          raise 'boom' if membership == failing

          delivered << membership
        end
      end
    end

    expect { described_class.perform_now }.not_to raise_error
    expect(delivered).to eq([ on ])
    expect(delivered).not_to include(off)
  end
end
