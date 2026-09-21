# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reminders', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, onboarding_current_step: 'onboarding_completed', country: 'BJ') }
  # Eager: a second space created later must not become "the first" (uuid order).
  let!(:space) { user.spaces.first }
  let!(:membership) { user.memberships.find_by(space: space) }
  let(:turbo) { { 'Accept' => 'text/vnd.turbo-stream.html' } }

  before { allow(Analytics).to receive(:track) }

  describe 'PATCH /reminder' do
    before { sign_in user, scope: :user }

    it 'turns the reminder on at the offered hour and answers in place' do
      patch reminder_path, params: { enabled: 1, hour: 13, source: 'habit' }, headers: turbo

      expect(membership.reload).to have_attributes(reminder_enabled: true, reminder_hour: 13)
      expect(response.body).to include('turbo-stream', 'reminder_card')
      expect(Analytics).to have_received(:track).with(user, 'reminder_enabled', source: 'habit', hour: 13)
    end

    it 'remembers a refusal and says where to turn it on later' do
      patch reminder_path, params: { decline: 1, source: 'onboarding' }, headers: turbo

      expect(membership.reload).to have_attributes(reminder_enabled: false, reminder_declined_at: be_present)
      expect(response.body).to include(CGI.escapeHTML(I18n.t('reminders.card.declined')))
    end

    it 'works mid-onboarding' do
      space.update!(onboarding_current_step: 'onboarding_first_day')

      patch reminder_path, params: { enabled: 1, hour: 20 }, headers: turbo

      expect(response).to have_http_status(:success)
      expect(membership.reload.reminder_enabled).to be(true)
    end

    it 'saves the settings form of another of the user spaces' do
      other = create(:space, user: user)

      patch reminder_path(space_id: other.id), params: { membership: { reminder_enabled: '1', reminder_hour: '7' } }

      expect(response).to have_http_status(:see_other)
      expect(user.memberships.find_by(space: other)).to have_attributes(reminder_enabled: true, reminder_hour: 7)
      expect(membership.reload.reminder_enabled).to be(false)
    end

    it 'turns it off and keeps the chosen hour' do
      membership.update!(reminder_enabled: true)

      patch reminder_path(space_id: space.id), params: { membership: { reminder_enabled: '0', reminder_hour: '9' } }

      expect(membership.reload).to have_attributes(reminder_enabled: false, reminder_hour: 9)
    end

    it 'never touches a space the user does not belong to' do
      stranger = create(:user).spaces.first

      patch reminder_path(space_id: stranger.id), params: { enabled: 1 }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'the e-mail stop link' do
    let(:token) { membership.signed_id(purpose: :reminder) }

    before { membership.update!(reminder_enabled: true) }

    it 'asks before stopping, without a session' do
      get reminder_unsubscribe_path(token: token)

      expect(response).to have_http_status(:success)
      expect(membership.reload.reminder_enabled).to be(true)
    end

    it 'stops the reminder on confirmation' do
      post reminder_unsubscribe_path, params: { token: token }

      expect(response).to have_http_status(:success)
      expect(membership.reload.reminder_enabled).to be(false)
    end

    it 'shrugs at a forged token' do
      post reminder_unsubscribe_path, params: { token: 'nope' }

      expect(response).to have_http_status(:success)
      expect(membership.reload.reminder_enabled).to be(true)
    end
  end
end
