# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReminderMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:membership) { user.memberships.first.tap { |m| m.space.update!(locale: 'fr') } }
  let(:mail) { described_class.daily(membership) }

  it 'goes to the member, in the space language, with a signed stop link' do
    expect(mail.to).to eq([ user.email ])
    expect(mail.subject).to eq(I18n.t('reminders.daily.title', locale: :fr))
    expect(mail.header['List-Unsubscribe'].value).to include('/reminder/unsubscribe?')

    token = mail.text_part.body.to_s[/token=([^\s&]+)/, 1]
    expect(Membership.find_signed(CGI.unescape(token), purpose: :reminder)).to eq(membership)
  end
end
