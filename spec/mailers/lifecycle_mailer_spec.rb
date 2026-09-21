# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LifecycleMailer, type: :mailer do
  let(:user) { create(:user, first_name: 'Awa') }
  let(:mail) { described_class.welcome(user, 'fr') }

  it 'names Spens in the subject, in the sign-up language' do
    expect(mail.to).to eq([ user.email ])
    expect(mail.subject).to eq(I18n.t('lifecycle_emails.welcome.subject', locale: :fr))
    expect(mail.subject).to include('Spens')
    expect(mail.html_part.body.to_s).to include('Awa')
  end

  it 'offers a one-click unsubscribe signed for the user' do
    expect(mail.header['List-Unsubscribe'].value).to include('/emails/unsubscribe?')
    expect(mail.header['List-Unsubscribe-Post'].value).to eq('List-Unsubscribe=One-Click')

    token = mail.text_part.body.to_s[%r{emails/unsubscribe\?token=([^\s&]+)}, 1]
    expect(User.find_signed(CGI.unescape(token), purpose: :lifecycle_emails)).to eq(user)
  end

  it 'tracks the click and the open' do
    expect(mail.html_part.body.to_s).to include('/e/welcome/click?', '/e/welcome/open.gif?')
    expect(mail.text_part.body.to_s).to include('/e/welcome/click?')
  end
end
