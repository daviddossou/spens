require 'rails_helper'

RSpec.describe OnboardingController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user, onboarding_current_step: :onboarding_financial_goal) }
  let(:completed_user) { create(:user, onboarding_current_step: :onboarding_completed, country: 'US') }

  describe 'GET #show' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        get :show
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when onboarding is completed' do
      before { sign_in completed_user }

      it 'redirects to dashboard' do
        get :show
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when onboarding is not completed' do
      before { sign_in user }

      it 'redirects to the current onboarding step path (financial goal)' do
        get :show
        expect(response).to redirect_to(onboarding_financial_goals_path)
      end

      it 'redirects to personal info step if onboarding_current_step is onboarding_personal_info' do
        user.update!(onboarding_current_step: :onboarding_personal_info)
        get :show
        expect(response).to redirect_to(onboarding_personal_info_path)
      end

      it 'redirects to account setup step if onboarding_current_step is onboarding_account_setup' do
        user.update!(onboarding_current_step: :onboarding_account_setup)
        get :show
        expect(response).to redirect_to(onboarding_account_setup_path)
      end

      it 'defaults to financial goals path for unknown step' do
        allow(user).to receive(:onboarding_current_step).and_return('unknown_step')
        get :show
        expect(response).to redirect_to(onboarding_financial_goals_path)
      end
    end
  end
end
