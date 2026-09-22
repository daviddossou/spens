# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailEventsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:token) { user.signed_id(purpose: :email_events) }

  before { allow(Analytics).to receive(:track) }

  describe 'GET /e/:email/open.gif' do
    it 'serves the pixel and records the open, even to an image proxy' do
      get email_open_path(email: 'welcome', token: token, format: :gif),
          headers: { 'User-Agent' => 'Mozilla/5.0 (Windows NT 5.1; rv:11.0) Gecko Firefox/11.0 (via ggpht.com GoogleImageProxy)' }

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('image/gif')
      expect(Analytics).to have_received(:track).with(user, 'lifecycle_email_opened', email: 'welcome', proxy: 'gmail')
    end

    it 'flags Apple Mail preloads' do
      get email_open_path(email: 'welcome', token: token, format: :gif), headers: { 'User-Agent' => 'Mozilla/5.0' }

      expect(Analytics).to have_received(:track).with(user, 'lifecycle_email_opened', email: 'welcome', proxy: 'apple')
    end

    it 'serves the pixel silently for a forged token' do
      get email_open_path(email: 'welcome', token: 'nope', format: :gif)

      expect(response).to have_http_status(:success)
      expect(Analytics).not_to have_received(:track)
    end
  end

  describe 'GET /e/:email/click' do
    it 'records the click and sends the user to the app' do
      get email_click_path(email: 'welcome', token: token)

      expect(response).to redirect_to(dashboard_path(utm_source: 'spens', utm_medium: 'email', utm_campaign: 'welcome'))
      expect(Analytics).to have_received(:track).with(user, 'lifecycle_email_clicked', email: 'welcome')
    end

    it 'records the return once the user is back in the app' do
      sign_in user, scope: :user
      get email_click_path(email: 'welcome', token: token)
      follow_redirect!

      expect(Analytics).to have_received(:track).with(user, 'lifecycle_email_returned', email: 'welcome').once
    end

    it 'ignores link scanners' do
      get email_click_path(email: 'welcome', token: token), headers: { 'User-Agent' => 'Proofpoint URL scanner' }

      expect(response).to have_http_status(:redirect)
      expect(Analytics).not_to have_received(:track)
    end
  end
end
