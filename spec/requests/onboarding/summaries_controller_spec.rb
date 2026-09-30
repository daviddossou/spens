# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::SummariesController', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, onboarding_current_step: 'onboarding_summary', country: 'BJ', currency: 'XOF') }
  let(:space) { user.spaces.first }
  let(:copy) { ->(key, **options) { CGI.escapeHTML(I18n.t("onboarding.summaries.show.#{key}", **options)) } }

  before do
    sign_in user, scope: :user
    create(:account, space: space, name: I18n.t('account_templates.wallet'), balance: 8500)
    create(:account, space: space, name: I18n.t('account_templates.mobile_money'), balance: 12_000)
  end

  it 'shows the total, the accounts biggest first, and the starting-point note' do
    get onboarding_summaries_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include(ApplicationController.helpers.money(20_500, 'XOF'), copy.call(:total_places, count: 2), copy.call(:note), copy.call(:enter))
    expect(response.body.index('Mobile Money')).to be < response.body.index('Wallet')
  end

  it 'completes onboarding and enters the app' do
    allow(Analytics).to receive(:track)

    patch onboarding_summaries_path

    expect(response).to redirect_to(dashboard_path)
    expect(space.reload).to be_onboarding_completed
    expect(Analytics).to have_received(:track).with(user, 'onboarding_step_completed', hash_including(step: 'summary'))
  end
end
