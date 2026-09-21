# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reminders::DailyReminder do
  include ActiveJob::TestHelper

  let(:user) { create(:user, onboarding_current_step: 'onboarding_completed', country: 'BJ', time_zone: 'Africa/Porto-Novo') }
  let(:space) { user.spaces.first }
  let(:membership) { user.memberships.find_by(space: space).tap { |m| m.update!(reminder_enabled: true, reminder_hour: 20) } }
  let(:reminder) { described_class.new(membership) }

  # 20:10 in Porto-Novo (UTC+1)
  before do
    travel_to Time.utc(2026, 9, 21, 19, 10)
    allow(Analytics).to receive(:track)
  end

  def note_something
    create(:transaction, space: space).update_column(:user_id, user.id)
  end

  describe '#due?' do
    it 'is due at the chosen hour on the member clock when nothing was noted' do
      expect(reminder).to be_due
    end

    it 'is not due at another hour' do
      membership.update!(reminder_hour: 21)

      expect(reminder).not_to be_due
    end

    it 'follows the member time zone, not the server' do
      user.update!(time_zone: 'Europe/Paris') # 21:10 there

      expect(reminder).not_to be_due
    end

    it 'is not due once something was noted today' do
      note_something

      expect(reminder).not_to be_due
    end

    it 'ignores what another member noted' do
      create(:transaction, space: space)

      expect(reminder).to be_due
    end

    it 'is not due when turned off, already sent today, or before onboarding ends' do
      expect(described_class.new(membership.tap { |m| m.update!(reminder_enabled: false) })).not_to be_due

      membership.update!(reminder_enabled: true, reminder_last_sent_on: Date.new(2026, 9, 21))
      expect(described_class.new(membership)).not_to be_due

      membership.update!(reminder_last_sent_on: nil)
      space.update!(onboarding_current_step: 'onboarding_first_day')
      expect(described_class.new(membership.reload)).not_to be_due
    end
  end

  describe '#deliver' do
    it 'pushes to the member browsers and sends no e-mail' do
      delivery = instance_double(Reminders::WebPushDelivery, call: 1)
      allow(Reminders::WebPushDelivery).to receive(:new).with(user).and_return(delivery)

      expect { expect(reminder.deliver).to eq(:push) }.not_to have_enqueued_mail(ReminderMailer, :daily)
      expect(delivery).to have_received(:call).with(hash_including(title: I18n.t('reminders.daily.title')))
      expect(membership.reload.reminder_last_sent_on).to eq(Date.new(2026, 9, 21))
    end

    it 'falls back to an e-mail when no browser was reached' do
      expect { expect(reminder.deliver).to eq(:email) }.to have_enqueued_mail(ReminderMailer, :daily)
      expect(Analytics).to have_received(:track).with(user, 'reminder_sent', channel: 'email', hour: 20)
    end

    it 'never sends twice the same day' do
      reminder.deliver

      expect { expect(described_class.new(membership.reload).deliver).to be_nil }.not_to have_enqueued_mail
    end
  end
end
