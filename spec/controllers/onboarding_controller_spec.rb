require 'rails_helper'

RSpec.describe OnboardingController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user, onboarding_current_step: :onboarding_financial_goal) }
  let(:completed_user) { create(:user, onboarding_current_step: :onboarding_completed, country: 'US') }
  let(:step_navigator_double) { instance_double(Onboarding::StepNavigator) }

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
      before do
        sign_in user
        allow(Onboarding::StepNavigator).to receive(:new).with(user).and_return(step_navigator_double)
      end

      it 'redirects to the path returned by StepNavigator' do
        allow(step_navigator_double).to receive(:current_step_path).and_return(onboarding_financial_goals_path)

        get :show

        expect(response).to redirect_to(onboarding_financial_goals_path)
      end

      it 'uses StepNavigator to determine the current step path' do
        allow(step_navigator_double).to receive(:current_step_path).and_return('/some/path')

        get :show

        expect(Onboarding::StepNavigator).to have_received(:new).with(user)
        expect(step_navigator_double).to have_received(:current_step_path)
      end
    end
  end
end
