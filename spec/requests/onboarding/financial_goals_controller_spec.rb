# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::FinancialGoalsController', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, onboarding_current_step: :onboarding_financial_goal) }
  let(:completed_user) { create(:user, onboarding_current_step: :onboarding_completed, country: 'US') }

  describe 'before_actions' do
    context 'when user is not authenticated' do
      it 'requires authentication' do
        get onboarding_financial_goals_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /onboarding/financial_goals' do
    before do
      sign_in user, scope: :user
    end

    it 'renders the show template' do
      get onboarding_financial_goals_path
      expect(response).to render_template(:show)
      expect(response).to have_http_status(:success)
    end

    it 'displays financial goals selection form' do
      get onboarding_financial_goals_path
      expect(response.body).to include('onboarding_financial_goal_form')
    end
  end

  describe 'PATCH /onboarding/financial_goals' do
    before do
      sign_in user, scope: :user
    end

    context 'with valid financial goals' do
      let(:valid_params) do
        {
          onboarding_financial_goal_form: {
            financial_goals: [ 'save_for_retirement', 'save_for_emergency' ]
          }
        }
      end

      it 'updates user financial goals' do
        patch onboarding_financial_goals_path, params: valid_params

        expect(user.reload.financial_goals).to contain_exactly('save_for_retirement', 'save_for_emergency')
      end

      it 'advances onboarding step' do
        patch onboarding_financial_goals_path, params: valid_params

        expect(user.reload.onboarding_current_step).to eq('onboarding_profile_setup')
      end

      it 'redirects to next onboarding step' do
        patch onboarding_financial_goals_path, params: valid_params

        expect(response).to redirect_to(onboarding_profile_setups_path)
      end
    end

    context 'with invalid financial goals' do
      let(:invalid_params) do
        {
          onboarding_financial_goal_form: {
            financial_goals: []
          }
        }
      end

      it 'does not update user financial goals' do
        original_goals = user.financial_goals
        patch onboarding_financial_goals_path, params: invalid_params

        expect(user.reload.financial_goals).to eq(original_goals)
      end

      it 'does not advance onboarding step' do
        original_step = user.onboarding_current_step
        patch onboarding_financial_goals_path, params: invalid_params

        expect(user.reload.onboarding_current_step).to eq(original_step)
      end

      it 'renders the form again with errors' do
        patch onboarding_financial_goals_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:show)
      end
    end

    context 'with disallowed financial goals' do
      let(:disallowed_params) do
        {
          onboarding_financial_goal_form: {
            financial_goals: [ 'invalid_goal', 'another_invalid' ]
          }
        }
      end

      it 'does not update user financial goals' do
        original_goals = user.financial_goals
        patch onboarding_financial_goals_path, params: disallowed_params

        expect(user.reload.financial_goals).to eq(original_goals)
      end

      it 'renders the form again with errors' do
        patch onboarding_financial_goals_path, params: disallowed_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('onboarding_financial_goal_form')
      end
    end

    context 'with missing required parameters' do
      it 'handles missing params gracefully' do
        patch onboarding_financial_goals_path, params: { invalid: 'params' }

        expect(response).to redirect_to(onboarding_financial_goals_path)
        expect(flash[:alert]).to eq("Something went wrong. Please try again.")
      end
    end

    context 'when not authenticated' do
      before { sign_out user }

      let(:valid_params) do
        {
          onboarding_financial_goal_form: {
            financial_goals: [ 'save_for_retirement' ]
          }
        }
      end

      it 'redirects to sign in page' do
        patch onboarding_financial_goals_path, params: valid_params

        expect(response).to redirect_to(new_user_session_path)
      end

      it 'does not update user data' do
        original_goals = user.financial_goals
        patch onboarding_financial_goals_path, params: valid_params

        expect(user.reload.financial_goals).to eq(original_goals)
      end
    end
  end
end
