# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PushSubscription, type: :model do
  it 'moves a browser endpoint to whoever registers it last' do
    first, second = create(:user), create(:user)
    keys = { endpoint: 'https://push.example.com/send/abc', p256dh: 'key', auth: 'secret' }

    described_class.register(user: first, **keys)
    described_class.register(user: second, **keys, user_agent: 'Firefox')

    expect(described_class.count).to eq(1)
    expect(described_class.first).to have_attributes(user: second, user_agent: 'Firefox')
  end
end
