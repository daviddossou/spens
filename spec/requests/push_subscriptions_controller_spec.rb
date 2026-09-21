# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PushSubscriptions', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, onboarding_current_step: 'onboarding_first_day') }
  let(:subscription) { { endpoint: 'https://push.example.com/send/abc', keys: { p256dh: 'key', auth: 'secret' } } }

  it 'requires a session' do
    post push_subscription_path, params: { subscription: subscription }, as: :json

    expect(PushSubscription.count).to eq(0)
  end

  context 'when signed in' do
    before { sign_in user, scope: :user }

    it 'stores the browser subscription, even mid-onboarding' do
      post push_subscription_path, params: { subscription: subscription }, as: :json

      expect(response).to have_http_status(:created)
      expect(user.push_subscriptions.first).to have_attributes(endpoint: subscription[:endpoint], p256dh: 'key', auth: 'secret')
    end

    it 'rejects an incomplete subscription' do
      post push_subscription_path, params: { subscription: { endpoint: 'https://push.example.com/x' } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'forgets a browser' do
      create(:push_subscription, user: user, endpoint: subscription[:endpoint])

      delete push_subscription_path, params: { endpoint: subscription[:endpoint] }

      expect(user.push_subscriptions).to be_empty
    end
  end
end
