# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingMailer, type: :mailer do
  it 'sends the member back to step 2, in the space language' do
    membership = create(:user).memberships.first.tap { |m| m.space.update!(locale: 'fr') }
    mail = described_class.accounts_nudge(membership)

    expect(mail.to).to eq([ membership.user.email ])
    expect(mail.subject).to eq(I18n.t('onboarding.accounts_nudge.title', locale: :fr))
    expect(mail.text_part.body.to_s).to include('/fr/onboarding/account_setups')
  end
end
