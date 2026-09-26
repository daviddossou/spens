# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::AccountSetupsController', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, onboarding_current_step: 'onboarding_account_setup', country: 'BJ', currency: 'XOF') }
  let(:space) { user.spaces.first }

  def add_account(name, balance)
    post accounts_path, params: { account: { account_name: name, current_balance: balance } }
  end

  it 'requires authentication' do
    get onboarding_account_setups_path

    expect(response).to have_http_status(:redirect)
  end

  context 'when signed in' do
    before { sign_in user, scope: :user }

    describe 'GET /onboarding/account_setups' do
      it 'opens on the invitation to add a first place, with a reminder for later' do
        get onboarding_account_setups_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t('onboarding.step_header_component.step', step: 2, total: 3))
        expect(response.body).to include(I18n.t('onboarding.account_setups.show.add_first'))
        expect(response.body).to include(CGI.escapeHTML(I18n.t('onboarding.account_setups.show.later')))
        expect(response.body).to match(/<turbo-frame[^>]*id="modal"/)
      end

      it 'shows the total and both groups once accounts exist' do
        add_account('Mobile Money MTN', '62350')
        add_account(I18n.t('account_templates.savings_account'), '48000')

        get onboarding_account_setups_path

        expect(response.body).to include(I18n.t('onboarding.account_setups.show.title_total'))
        expect(response.body).to include(I18n.t('accounts.index.everyday'), I18n.t('accounts.index.set_aside'))
        expect(response.body).to include(I18n.t('onboarding.account_setups.show.total_places', count: 2))
        expect(response.body).not_to include(CGI.escapeHTML(I18n.t('onboarding.account_setups.show.later')))
      end
    end

    describe 'the real new-account sheet during onboarding' do
      it 'is reachable before onboarding is completed' do
        get new_account_path

        expect(response).to have_http_status(:success)
      end

      it 'comes back to the step after a create, without a flash' do
        add_account('Porte-monnaie', '12050')

        expect(response).to redirect_to(onboarding_account_setups_path)
        expect(flash[:notice]).to be_nil
        expect(space.accounts.pluck(:name)).to eq([ 'Porte-monnaie' ])
      end

      it 'keeps the rest of the accounts pages behind onboarding' do
        get accounts_path

        expect(response).to redirect_to(onboarding_path)
      end
    end

    describe 'PATCH /onboarding/account_setups' do
      it 'moves on to the first day' do
        add_account('Porte-monnaie', '12050')

        patch onboarding_account_setups_path

        expect(response).to redirect_to(onboarding_first_days_path)
        expect(space.reload.onboarding_current_step).to eq('onboarding_first_day')
      end

      it 'refuses to move on without an account' do
        patch onboarding_account_setups_path

        expect(response).to redirect_to(onboarding_account_setups_path)
        expect(space.reload.onboarding_current_step).to eq('onboarding_account_setup')
      end

      it 'completes onboarding for someone who stops here' do
        add_account('Porte-monnaie', '12050')

        patch onboarding_account_setups_path, params: { stop: 1 }

        expect(response).to redirect_to(dashboard_path)
        expect(space.reload).to be_onboarding_completed
      end

      it 'works for a space whose country could not be guessed' do
        space.update_columns(country: nil)
        add_account('Porte-monnaie', '12050')

        patch onboarding_account_setups_path, params: { stop: 1 }

        expect(space.reload).to be_onboarding_completed
      end
    end

    describe 'POST /onboarding/account_setups/nudge' do
      it 'schedules a one-off nudge and keeps the user on the step' do
        allow(Analytics).to receive(:track)
        travel_to Time.utc(2026, 9, 22, 9) do # 10:00 in Porto-Novo
          post nudge_onboarding_account_setups_path, params: { in: 'tonight' }
        end

        expect(response).to redirect_to(onboarding_account_setups_path(nudged: 1))
        expect(user.memberships.find_by(space: space).accounts_nudge_at).to eq(Time.utc(2026, 9, 22, 19))
        expect(space.reload.onboarding_current_step).to eq('onboarding_account_setup')
      end

      it 'ignores an unknown delay' do
        post nudge_onboarding_account_setups_path, params: { in: 'never' }

        expect(response).to redirect_to(onboarding_account_setups_path)
        expect(user.memberships.find_by(space: space).accounts_nudge_at).to be_nil
      end
    end
  end
end
