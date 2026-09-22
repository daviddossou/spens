# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WelcomeEmailJob, type: :job do
  let(:user) { create(:user) }

  before { allow(Analytics).to receive(:track) }

  it 'sends the welcome e-mail once and records it' do
    expect { described_class.perform_now(user, 'fr') }.to change(ActionMailer::Base.deliveries, :count).by(1)

    expect(user.reload.welcome_email_sent_at).to be_present
    expect(Analytics).to have_received(:track).with(user, 'lifecycle_email_sent', email: 'welcome', locale: 'fr')

    expect { described_class.perform_now(user, 'fr') }.not_to change(ActionMailer::Base.deliveries, :count)
  end

  it 'stays silent for an unsubscribed user' do
    user.update!(lifecycle_emails: false)

    expect { described_class.perform_now(user, 'fr') }.not_to change(ActionMailer::Base.deliveries, :count)
    expect(Analytics).not_to have_received(:track)
  end
end
