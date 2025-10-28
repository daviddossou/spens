# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OnboardingRedirection, type: :controller do
  include Devise::Test::ControllerHelpers

  it_behaves_like 'a controller concern', OnboardingRedirection
  it_behaves_like 'a concern with before_actions', OnboardingRedirection, [ :redirect_to_onboarding ]

  controller(ApplicationController) do
    include OnboardingRedirection
    # Skip other concerns that interfere with testing
    skip_before_action :set_locale, if: -> { true }
    skip_before_action :configure_permitted_parameters, if: -> { true }

    def index
      render plain: 'success'
    end

    def destroy
      render plain: 'destroyed'
    end
  end

  let(:user) { create(:user) }

  describe '#redirect_to_onboarding' do
    context 'when user is not signed in' do
      it 'does not redirect to onboarding' do
        get :index
        expect(response).to have_http_status(:success)
        expect(response.body).to eq('success')
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      context 'when onboarding is completed' do
        before { allow(user).to receive(:onboarding_completed?).and_return(true) }

        it 'does not redirect to onboarding' do
          get :index
          expect(response).to have_http_status(:success)
          expect(response.body).to eq('success')
        end
      end

      context 'when onboarding is not completed' do
        before { allow(user).to receive(:onboarding_completed?).and_return(false) }

        it 'redirects to onboarding path' do
          get :index
          expect(response).to redirect_to(onboarding_path)
        end

        context 'when on onboarding controller' do
          before do
            allow(controller).to receive(:controller_name).and_return('onboarding')
          end

          it 'does not redirect' do
            get :index
            expect(response).to have_http_status(:success)
            expect(response.body).to eq('success')
          end
        end
      end
    end
  end

  describe '#onboarding_redirection_exempt?' do
    before { sign_in user }

    context 'when controller is devise controller' do
      before { allow(controller).to receive(:devise_controller?).and_return(true) }

      it 'is exempt from redirection' do
        expect(controller.send(:onboarding_redirection_exempt?)).to be true
      end
    end

    context 'when controller is rails/health' do
      before { allow(controller).to receive(:controller_name).and_return('rails/health') }

      it 'is exempt from redirection' do
        expect(controller.send(:onboarding_redirection_exempt?)).to be true
      end
    end

    context 'when action is destroy' do
      before do
        allow(controller).to receive(:action_name).and_return('destroy')
        allow(controller).to receive(:devise_controller?).and_return(false)
        allow(controller).to receive(:controller_name).and_return('sessions')
      end

      it 'is exempt from redirection' do
        expect(controller.send(:onboarding_redirection_exempt?)).to be true
      end
    end

    context 'when controller is not exempt' do
      before do
        allow(controller).to receive(:devise_controller?).and_return(false)
        allow(controller).to receive(:controller_name).and_return('posts')
        allow(controller).to receive(:action_name).and_return('index')
      end

      it 'is not exempt from redirection' do
        expect(controller.send(:onboarding_redirection_exempt?)).to be false
      end
    end
  end

  describe '#onboarding_controller?' do
    context 'when controller name is onboarding' do
      before { allow(controller).to receive(:controller_name).and_return('onboarding') }

      it 'returns true' do
        expect(controller.send(:onboarding_controller?)).to be true
      end
    end

    context 'when controller name is financial_goals' do
      before { allow(controller).to receive(:controller_name).and_return('financial_goals') }

      it 'returns true' do
        expect(controller.send(:onboarding_controller?)).to be true
      end
    end

    context 'when controller name is profile_setups' do
      before { allow(controller).to receive(:controller_name).and_return('profile_setups') }

      it 'returns true' do
        expect(controller.send(:onboarding_controller?)).to be true
      end
    end

    context 'when controller name is account_setups' do
      before { allow(controller).to receive(:controller_name).and_return('account_setups') }

      it 'returns true' do
        expect(controller.send(:onboarding_controller?)).to be true
      end
    end

    context 'when controller name is not an onboarding controller' do
      before { allow(controller).to receive(:controller_name).and_return('posts') }

      it 'returns false' do
        expect(controller.send(:onboarding_controller?)).to be false
      end
    end
  end
end
