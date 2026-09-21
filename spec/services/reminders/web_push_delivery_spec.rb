# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reminders::WebPushDelivery do
  let(:user) { create(:user) }
  let(:message) { { title: 'Title', body: 'Body', url: '/dashboard' } }

  before do
    allow(Rails.application.config.x).to receive(:web_push)
      .and_return(public_key: 'pub', private_key: 'priv', subject: 'mailto:contact@spens.me')
  end

  it 'sends to every browser and counts the ones reached' do
    create_list(:push_subscription, 2, user: user)
    allow(WebPush).to receive(:payload_send)

    expect(described_class.new(user).call(**message)).to eq(2)
    expect(WebPush).to have_received(:payload_send).twice.with(hash_including(message: message.to_json))
    expect(user.push_subscriptions.pluck(:last_used_at)).to all(be_present)
  end

  it 'forgets a subscription the push service no longer knows' do
    create(:push_subscription, user: user)
    response = instance_double(Net::HTTPGone, body: 'gone', code: '410', message: 'Gone')
    allow(response).to receive(:[]).and_return(nil)
    allow(WebPush).to receive(:payload_send).and_raise(WebPush::ExpiredSubscription.new(response, 'push.example.com'))

    expect(described_class.new(user).call(**message)).to eq(0)
    expect(PushSubscription.count).to eq(0)
  end

  it 'reaches nobody without VAPID keys' do
    allow(Rails.application.config.x).to receive(:web_push).and_return(nil)
    create(:push_subscription, user: user)

    expect(described_class.new(user).call(**message)).to eq(0)
  end
end
