require 'rails_helper'

RSpec.describe 'OnboardingController', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, onboarding_current_step: :onboarding_financial_goal) }
  let(:completed_user) { create(:user, onboarding_current_step: :onboarding_completed, country: 'US', currency: 'USD') }

  describe 'GET /onboarding' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        get onboarding_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when onboarding is completed' do
      before { sign_in completed_user, scope: :user }

      it 'redirects to dashboard' do
        get onboarding_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when onboarding is in progress' do
      before { sign_in user, scope: :user }

      it 'redirects to the current onboarding step' do
        get onboarding_path

        # User is at financial_goal step, should redirect there
        expect(response).to redirect_to(onboarding_financial_goals_path)
      end
    end
  end
end
