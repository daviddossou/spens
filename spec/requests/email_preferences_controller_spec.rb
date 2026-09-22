# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailPreferencesController, type: :request do
  let(:user) { create(:user) }
  let(:token) { user.signed_id(purpose: :lifecycle_emails) }

  it 'asks before unsubscribing, without a session' do
    get email_unsubscribe_path(token: token)

    expect(response).to have_http_status(:success)
    expect(user.reload.lifecycle_emails?).to be(true)
  end

  it 'unsubscribes on confirmation' do
    post email_unsubscribe_path, params: { token: token }

    expect(response).to have_http_status(:success)
    expect(user.reload.lifecycle_emails?).to be(false)
  end

  it "unsubscribes from a mail client's one-click button" do
    post email_unsubscribe_path(token: token), params: { 'List-Unsubscribe' => 'One-Click' }

    expect(user.reload.lifecycle_emails?).to be(false)
  end

  it 'shrugs at a forged token' do
    post email_unsubscribe_path, params: { token: 'nope' }

    expect(response).to have_http_status(:success)
    expect(user.reload.lifecycle_emails?).to be(true)
  end
end
