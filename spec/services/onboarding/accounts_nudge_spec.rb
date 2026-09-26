# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::AccountsNudge do
  include ActiveJob::TestHelper

  let(:user) { create(:user, onboarding_current_step: 'onboarding_account_setup') }
  let(:membership) { user.memberships.first.tap { |m| m.update!(accounts_nudge_at: 1.minute.ago) } }

  before { allow(Analytics).to receive(:track) }

  it 'e-mails when no browser is reached, once' do
    expect { expect(described_class.new(membership).deliver).to eq(:email) }
      .to have_enqueued_mail(OnboardingMailer, :accounts_nudge).with(membership)
    expect(membership.reload.accounts_nudge_at).to be_nil
  end

  it 'pushes instead when a browser is reached' do
    allow(Reminders::WebPushDelivery).to receive(:new).and_return(instance_double(Reminders::WebPushDelivery, call: 1))

    expect { expect(described_class.new(membership).deliver).to eq(:push) }.not_to have_enqueued_mail
  end

  it 'sends nothing once an account exists' do
    create(:account, space: membership.space, user: user)

    expect { expect(described_class.new(membership).deliver).to eq(:skipped) }.not_to have_enqueued_mail
    expect(membership.reload.accounts_nudge_at).to be_nil
  end

  describe 'DELAYS' do
    let(:zone) { Time.find_zone('Africa/Porto-Novo') }

    it 'lands tonight at 8 PM, or an hour later when it is already evening' do
      travel_to(zone.local(2026, 9, 22, 10)) { expect(described_class::DELAYS['tonight'].call(zone)).to eq(zone.local(2026, 9, 22, 20)) }
      travel_to(zone.local(2026, 9, 22, 21)) { expect(described_class::DELAYS['tonight'].call(zone)).to eq(zone.local(2026, 9, 22, 22)) }
    end

    it 'lands tomorrow at 9 AM' do
      travel_to(zone.local(2026, 9, 22, 23)) { expect(described_class::DELAYS['tomorrow'].call(zone)).to eq(zone.local(2026, 9, 23, 9)) }
    end
  end
end
