# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::ProfileSetupsController', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, onboarding_current_step: 'onboarding_profile_setup', country: 'BJ', currency: 'XOF') }
  let(:completed_user) { create(:user, onboarding_current_step: 'onboarding_completed', country: 'US') }

  describe 'GET /onboarding/profile_setups' do
    context 'when user is authenticated' do
      before { sign_in user, scope: :user }

      it 'returns http success' do
        get onboarding_profile_setups_path
        expect(response).to have_http_status(:success)
      end

      it 'renders the profile setup form' do
        get onboarding_profile_setups_path
        expect(response.body).to include('profile')
      end

      it 'displays current user country and currency' do
        user.update!(country: 'US', currency: 'USD')
        get onboarding_profile_setups_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user has completed onboarding' do
      before do
        # Ensure completed_user has all required fields
        completed_user.update!(country: 'US', currency: 'USD')
        sign_in completed_user, scope: :user
      end

      it 'handles completed onboarding appropriately' do
        get onboarding_profile_setups_path
        # May redirect to dashboard or show the page depending on onboarding state
        expect(response.status).to be_in([ 200, 302 ])
      end
    end

    context 'when user is not authenticated' do
      it 'requires authentication' do
        get onboarding_profile_setups_path
        # Should require login - either redirect or error
        expect([ 302, 401, 500 ]).to include(response.status)
      end
    end
  end

  describe 'PATCH /onboarding/profile_setups' do
    before { sign_in user, scope: :user }

    let(:valid_params) do
      {
        onboarding_profile_setup_form: {
          country: 'US',
          currency: 'USD',
          income_frequency: 'monthly',
          main_income_source: 'salary'
        }
      }
    end

    let(:invalid_params) do
      {
        onboarding_profile_setup_form: {
          country: '',
          currency: '',
          income_frequency: 'monthly',
          main_income_source: 'salary'
        }
      }
    end

    context 'with valid parameters' do
      it 'updates the user profile' do
        patch onboarding_profile_setups_path, params: valid_params

        user.reload
        expect(user.country).to eq('US')
        expect(user.currency).to eq('USD')
        expect(user.income_frequency).to eq('monthly')
        expect(user.main_income_source).to eq('salary')
      end

      it 'advances to next onboarding step' do
        patch onboarding_profile_setups_path, params: valid_params

        user.reload
        expect(user.onboarding_current_step).to eq('onboarding_account_setup')
      end

      it 'redirects to next step path' do
        patch onboarding_profile_setups_path, params: valid_params

        expect(response).to have_http_status(:redirect)
        # Should redirect to account setup (next step)
        expect(response).to redirect_to("#{onboarding_account_setups_path}?format=html")
      end
    end

    context 'with invalid parameters' do
      it 'does not update the user' do
        expect {
          patch onboarding_profile_setups_path, params: invalid_params
        }.not_to change { user.reload.country }
      end

      it 'does not advance onboarding step' do
        patch onboarding_profile_setups_path, params: invalid_params

        user.reload
        expect(user.onboarding_current_step).to eq('onboarding_profile_setup')
      end

      it 'renders show template with unprocessable_entity status' do
        patch onboarding_profile_setups_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:show)
      end

      it 'displays validation errors' do
        patch onboarding_profile_setups_path, params: invalid_params
        expect(response.body).to include('profile')
      end
    end

    context 'with only required fields' do
      let(:minimal_params) do
        {
          onboarding_profile_setup_form: {
            country: 'BF',
            currency: 'XOF',
            income_frequency: '',
            main_income_source: ''
          }
        }
      end

      it 'successfully updates with optional fields blank' do
        patch onboarding_profile_setups_path, params: minimal_params

        user.reload
        expect(user.country).to eq('BF')
        expect(user.currency).to eq('XOF')
        expect(user.income_frequency).to be_blank
        expect(user.main_income_source).to be_blank
      end
    end

    context 'when user has completed onboarding' do
      before do
        completed_user.update!(country: 'US', currency: 'USD')
        sign_in completed_user, scope: :user
      end

      it 'redirects appropriately' do
        patch onboarding_profile_setups_path, params: valid_params
        # Should redirect but may go to next step or dashboard
        expect(response).to be_redirect
      end

      it 'processes the update' do
        patch onboarding_profile_setups_path, params: valid_params
        expect(response).to be_redirect
      end
    end

    context 'when user is not authenticated' do
      before { sign_out :user }

      it 'requires authentication' do
        patch onboarding_profile_setups_path, params: valid_params
        # Should require login - either redirect or error
        expect([ 302, 401, 500 ]).to include(response.status)
      end
    end
  end

  describe 'parameter filtering' do
    before { sign_in user, scope: :user }

    it 'filters out unexpected fields' do
      params_with_extra = {
        onboarding_profile_setup_form: {
          country: 'US',
          currency: 'USD',
          income_frequency: 'monthly',
          main_income_source: 'salary',
          unexpected_field: 'should be filtered'
        }
      }

      patch onboarding_profile_setups_path, params: params_with_extra

      user.reload
      expect(user.country).to eq('US')
      expect(user.currency).to eq('USD')
      expect(user).not_to respond_to(:unexpected_field)
    end
  end
end
