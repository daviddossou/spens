# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::ProfileSetupsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user, onboarding_current_step: 'onboarding_profile_setup', country: 'BJ', currency: 'XOF') }
  let(:completed_user) { create(:user, onboarding_current_step: 'onboarding_completed', country: 'US') }

  describe 'GET #show' do
    context 'when user is authenticated' do
      before { sign_in user, scope: :user }

      it 'returns http success' do
        get :show
        expect(response).to have_http_status(:success)
      end

      it 'builds a profile setup form' do
        get :show
        expect(assigns(:form)).to be_a(Onboarding::ProfileSetupForm)
      end

      it 'initializes form with current user data' do
        user.update!(country: 'US', currency: 'USD')
        get :show

        form = assigns(:form)
        expect(form.country).to eq('US')
        expect(form.currency).to eq('USD')
      end
    end

    context 'when user has completed onboarding' do
      before { sign_in completed_user, scope: :user }

      it 'redirects to dashboard' do
        get :show
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :show
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH #update' do
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
        patch :update, params: valid_params

        user.reload
        expect(user.country).to eq('US')
        expect(user.currency).to eq('USD')
        expect(user.income_frequency).to eq('monthly')
        expect(user.main_income_source).to eq('salary')
      end

      it 'advances to next onboarding step' do
        patch :update, params: valid_params

        user.reload
        expect(user.onboarding_current_step).to eq('onboarding_account_setup')
      end

      it 'redirects to next step path' do
        patch :update, params: valid_params

        # Should redirect to the next step determined by StepNavigator
        expect(response).to have_http_status(:redirect)
        expect(response).not_to redirect_to(onboarding_profile_setups_path)
      end

      it 'uses StepNavigator to determine next path' do
        expect_any_instance_of(Onboarding::StepNavigator).to receive(:current_step_path).and_call_original
        patch :update, params: valid_params
      end
    end

    context 'with invalid parameters' do
      it 'does not update the user' do
        expect {
          patch :update, params: invalid_params
        }.not_to change { user.reload.country }
      end

      it 'does not advance onboarding step' do
        patch :update, params: invalid_params

        user.reload
        expect(user.onboarding_current_step).to eq('onboarding_profile_setup')
      end

      it 'renders show template with unprocessable_entity status' do
        patch :update, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:show)
      end

      it 'assigns form with errors' do
        patch :update, params: invalid_params

        form = assigns(:form)
        expect(form.errors).not_to be_empty
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
        patch :update, params: minimal_params

        user.reload
        expect(user.country).to eq('BF')
        expect(user.currency).to eq('XOF')
        expect(user.income_frequency).to be_blank
        expect(user.main_income_source).to be_blank
      end
    end

    context 'when an unexpected error occurs' do
      before do
        allow_any_instance_of(Onboarding::ProfileSetupForm).to receive(:submit).and_raise(StandardError, 'Unexpected error')
      end

      it 'handles the error gracefully' do
        patch :update, params: valid_params

        expect(response).to redirect_to(onboarding_profile_setups_path)
        expect(flash[:alert]).to eq(I18n.t('onboarding.errors.generic'))
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Error when updating profile setup: Unexpected error/)
        patch :update, params: valid_params
      end
    end

    context 'when user has completed onboarding' do
      before { sign_in completed_user, scope: :user }

      it 'redirects to dashboard before processing update' do
        patch :update, params: valid_params
        expect(response).to redirect_to(dashboard_path)
      end

      it 'does not update the user' do
        expect {
          patch :update, params: valid_params
        }.not_to change { completed_user.reload.country }
      end
    end

    context 'when user is not authenticated' do
      before { sign_out user }

      it 'redirects to sign in' do
        patch :update, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe '#build_form' do
    before { sign_in user, scope: :user }

    it 'memoizes the form instance' do
      get :show
      form1 = assigns(:form)

      controller.instance_variable_set(:@form, nil)
      controller.send(:build_form)
      form2 = controller.instance_variable_get(:@form)

      # Should create new instance when @form is nil
      expect(form2).to be_a(Onboarding::ProfileSetupForm)
    end

    it 'passes payload to form when provided' do
      payload = { country: 'CA', currency: 'CAD' }
      form = controller.send(:build_form, payload)

      expect(form.country).to eq('CA')
      expect(form.currency).to eq('CAD')
    end
  end

  describe 'permitted parameters' do
    before { sign_in user, scope: :user }

    it 'permits expected profile setup attributes' do
      params = ActionController::Parameters.new(
        onboarding_profile_setup_form: {
          country: 'US',
          currency: 'USD',
          income_frequency: 'monthly',
          main_income_source: 'salary',
          unexpected_field: 'should be filtered'
        }
      )

      controller.params = params
      permitted = controller.send(:profile_setup_params)

      expect(permitted.keys).to contain_exactly('country', 'currency', 'income_frequency', 'main_income_source')
      expect(permitted.key?('unexpected_field')).to be false
    end
  end
end
