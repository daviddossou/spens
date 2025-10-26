# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::FinancialGoalsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user, onboarding_current_step: :onboarding_financial_goal) }
  let(:completed_user) { create(:user, onboarding_current_step: :onboarding_completed, country: 'US') }
  let(:form_double) { instance_double(Onboarding::FinancialGoalForm) }
  let(:step_navigator_double) { instance_double(Onboarding::StepNavigator) }

  describe 'before_actions' do
    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get :show
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user has completed onboarding' do
      before do
        sign_in completed_user, scope: :user
      end

      it 'redirects to dashboard' do
        get :show
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe 'GET #show' do
    before do
      sign_in user, scope: :user
      allow(Onboarding::FinancialGoalForm).to receive(:new).and_return(form_double)
    end

    it 'renders the show template' do
      get :show
      expect(response).to render_template(:show)
      expect(response).to have_http_status(:success)
    end

    it 'builds the form with current user and empty payload' do
      expect(Onboarding::FinancialGoalForm).to receive(:new).with(user, {})
      get :show
    end

    it 'assigns the form to @form' do
      get :show
      expect(assigns(:form)).to eq(form_double)
    end
  end

  describe 'PATCH #update' do
    let(:financial_goals_params) do
      {
        onboarding_financial_goal_form: {
          financial_goals: ['retirement', 'emergency_fund']
        }
      }
    end

    before do
      sign_in user, scope: :user
      allow(Onboarding::FinancialGoalForm).to receive(:new).and_return(form_double)
      allow(Onboarding::StepNavigator).to receive(:new).with(user).and_return(step_navigator_double)
    end

    context 'when form submission is successful' do
      before do
        allow(form_double).to receive(:submit).and_return(true)
        allow(step_navigator_double).to receive(:current_step_path).and_return('/next-step')
        allow(user).to receive(:reload)
      end

      it 'builds form with submitted parameters' do
        expected_params = ActionController::Parameters.new(financial_goals: ['retirement', 'emergency_fund']).permit(financial_goals: [])
        expect(Onboarding::FinancialGoalForm).to receive(:new).with(user, expected_params)

        patch :update, params: financial_goals_params
      end

      it 'calls submit on the form' do
        expect(form_double).to receive(:submit)
        patch :update, params: financial_goals_params
      end

      it 'reloads the user' do
        expect_any_instance_of(User).to receive(:reload)

        patch :update, params: financial_goals_params
      end

      it 'redirects to next onboarding step' do
        patch :update, params: financial_goals_params
        expect(response).to redirect_to('/next-step')
      end

      it 'uses StepNavigator to determine next step' do
        expect(Onboarding::StepNavigator).to receive(:new).with(user)
        expect(step_navigator_double).to receive(:current_step_path)
        patch :update, params: financial_goals_params
      end
    end

    context 'when form submission fails' do
      before do
        allow(form_double).to receive(:submit).and_return(false)
      end

      it 'renders show template with unprocessable_entity status' do
        patch :update, params: financial_goals_params
        expect(response).to render_template(:show)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not redirect' do
        patch :update, params: financial_goals_params
        expect(response).not_to be_redirect
      end
    end

    context 'when an exception is raised' do
      before do
        allow(form_double).to receive(:submit).and_raise(StandardError.new('Test error'))
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with('Error when updating financial goals: Test error')
        patch :update, params: financial_goals_params
      end

      it 'redirects to financial goals path with alert' do
        patch :update, params: financial_goals_params
        expect(response).to redirect_to(onboarding_financial_goals_path)
        expect(flash[:alert]).to be_present
      end
    end

    context 'with invalid parameters' do
      it 'handles missing required params gracefully' do
        patch :update, params: { invalid: 'params' }

        expect(response).to redirect_to(onboarding_financial_goals_path)
        expect(flash[:alert]).to eq("Something went wrong. Please try again.")
      end

      it 'filters unpermitted parameters' do
        params_with_extra = {
          onboarding_financial_goal_form: {
            financial_goals: ['retirement'],
            unauthorized_field: 'should be filtered'
          }
        }

        # The controller should only pass permitted params to the form
        expected_params = ActionController::Parameters.new(financial_goals: ['retirement']).permit(financial_goals: [])
        expect(Onboarding::FinancialGoalForm).to receive(:new).with(user, expected_params)

        allow(form_double).to receive(:submit).and_return(true)
        allow(step_navigator_double).to receive(:current_step_path).and_return('/next')
        allow(user).to receive(:reload)

        patch :update, params: params_with_extra
      end
    end
  end

  describe 'private methods' do
    before do
      sign_in user, scope: :user
    end

    describe '#build_form' do
      it 'creates new form with user and payload' do
        payload = { financial_goals: ['test'] }
        expect(Onboarding::FinancialGoalForm).to receive(:new).with(user, payload)

        controller.send(:build_form, payload)
      end

      it 'memoizes the form instance' do
        allow(Onboarding::FinancialGoalForm).to receive(:new).and_return(form_double)

        # First call creates the form
        result1 = controller.send(:build_form)
        # Second call returns the same instance
        result2 = controller.send(:build_form)

        expect(result1).to eq(result2)
        expect(Onboarding::FinancialGoalForm).to have_received(:new).once
      end
    end

    describe '#financial_goals_params' do
      let(:params_hash) do
        ActionController::Parameters.new({
          onboarding_financial_goal_form: {
            financial_goals: ['retirement', 'savings'],
            unauthorized_param: 'not allowed'
          }
        })
      end

      before do
        allow(controller).to receive(:params).and_return(params_hash)
      end

      it 'permits only financial_goals array' do
        result = controller.send(:financial_goals_params)
        expect(result.to_h).to eq({ 'financial_goals' => ['retirement', 'savings'] })
      end

      it 'requires onboarding_financial_goal_form key' do
        params_without_required = ActionController::Parameters.new({
          other_form: { financial_goals: ['test'] }
        })
        allow(controller).to receive(:params).and_return(params_without_required)

        expect {
          controller.send(:financial_goals_params)
        }.to raise_error(ActionController::ParameterMissing)
      end
    end

    describe '#redirect_if_completed' do
      context 'when onboarding is completed' do
        before { sign_in completed_user, scope: :user }

        it 'redirects to dashboard' do
          get :show
          expect(response).to redirect_to(dashboard_path)
        end
      end

      context 'when onboarding is not completed' do
        before { sign_in user, scope: :user }

        it 'does not redirect' do
          get :show
          expect(response).to be_successful
        end
      end
    end

    describe '#next_step_path' do
      before do
        sign_in user, scope: :user
        allow_any_instance_of(User).to receive(:reload)
        allow(Onboarding::StepNavigator).to receive(:new).with(an_instance_of(User)).and_return(step_navigator_double)
        allow(step_navigator_double).to receive(:current_step_path).and_return('/custom-path')
      end

      it 'reloads the user' do
        expect_any_instance_of(User).to receive(:reload)
        controller.send(:next_step_path)
      end

      it 'creates StepNavigator with current user' do
        expect(Onboarding::StepNavigator).to receive(:new).with(an_instance_of(User))
        controller.send(:next_step_path)
      end

      it 'returns the current step path from navigator' do
        result = controller.send(:next_step_path)
        expect(result).to eq('/custom-path')
      end
    end
  end

  describe 'integration scenarios' do
    before do
      sign_in user, scope: :user
    end

    context 'complete onboarding flow' do
      it 'handles successful form submission and navigation' do
        allow(Onboarding::FinancialGoalForm).to receive(:new).and_return(form_double)
        allow(form_double).to receive(:submit).and_return(true)
        allow(Onboarding::StepNavigator).to receive(:new).with(an_instance_of(User)).and_return(step_navigator_double)
        allow(step_navigator_double).to receive(:current_step_path).and_return('/next-step')
        allow_any_instance_of(User).to receive(:reload)

        patch :update, params: {
          onboarding_financial_goal_form: {
            financial_goals: ['retirement', 'emergency_fund', 'house']
          }
        }

        expect(form_double).to have_received(:submit)
        expect(step_navigator_double).to have_received(:current_step_path)
        expect(response).to redirect_to('/next-step')
      end
    end

    context 'error recovery' do
      it 'gracefully handles form submission errors' do
        allow(Onboarding::FinancialGoalForm).to receive(:new).and_return(form_double)
        allow(form_double).to receive(:submit).and_raise('Database connection error')

        expect(Rails.logger).to receive(:error)

        patch :update, params: {
          onboarding_financial_goal_form: { financial_goals: ['test'] }
        }

        expect(response).to redirect_to(onboarding_financial_goals_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'security and edge cases' do
    context 'with malformed parameters' do
      before do
        sign_in user, scope: :user
      end

      it 'handles empty financial_goals array' do
        allow(Onboarding::FinancialGoalForm).to receive(:new).and_return(form_double)
        allow(form_double).to receive(:submit).and_return(true)
        allow(Onboarding::StepNavigator).to receive(:new).and_return(step_navigator_double)
        allow(step_navigator_double).to receive(:current_step_path).and_return('/next')
        allow(user).to receive(:reload)

        patch :update, params: {
          onboarding_financial_goal_form: { financial_goals: [] }
        }

        expect(response).to be_redirect
      end

      it 'handles nil financial_goals' do
        params_with_nil = {
          onboarding_financial_goal_form: { financial_goals: nil }
        }

        expect {
          patch :update, params: params_with_nil
        }.not_to raise_error
      end
    end
  end
end
