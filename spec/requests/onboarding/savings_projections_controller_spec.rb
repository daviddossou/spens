# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Onboarding::SavingsProjectionsController', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, onboarding_current_step: 'onboarding_savings_projection') }
  let(:space) { user.spaces.first }

  before { space.update_columns(country: nil) }

  describe 'GET /onboarding/savings_projections' do
    it 'requires authentication' do
      get onboarding_savings_projections_path

      expect(response).to have_http_status(:redirect)
    end

    context 'when signed in' do
      before { sign_in user, scope: :user }

      it 'renders the calculation as step 1 of 3' do
        get onboarding_savings_projections_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t('onboarding.step_header_component.step', step: 1, total: 3))
        expect(response.body).to include("180 000")
      end

      it 'shows the currency of the Cloudflare country' do
        get onboarding_savings_projections_path, headers: { 'CF-IPCountry' => 'FR' }

        expect(response.body).to include('EUR')
      end

      it 'tracks the step view' do
        allow(Analytics).to receive(:track)

        get onboarding_savings_projections_path

        expect(Analytics).to have_received(:track)
          .with(user, 'onboarding_step_viewed', hash_including(step: 'savings_projection'))
      end
    end
  end

  describe 'PATCH /onboarding/savings_projections' do
    before { sign_in user, scope: :user }

    let(:params) { { onboarding_savings_projection_form: { monthly_income: '200 000', savings_rate: '20' } } }

    it 'saves the answers with the guessed country and moves on' do
      patch onboarding_savings_projections_path, params: params.merge(landing_country: 'BJ', landing_currency: 'XOF')

      expect(response).to redirect_to(onboarding_account_setups_path)
      expect(space.reload).to have_attributes(monthly_income: 200_000, savings_rate: 20, country: 'BJ', currency: 'XOF')
    end

    it 'tracks the rate but never the income' do
      allow(Analytics).to receive(:track)

      patch onboarding_savings_projections_path, params: params

      expect(Analytics).to have_received(:track).with(user, 'onboarding_step_completed', satisfy { |properties|
        properties[:step] == 'savings_projection' && properties[:savings_rate] == 20 &&
          properties.none? { |key, _| key.to_s.include?('income') && key != :income_frequency }
      })
    end

    it 're-renders with an error when the income is missing' do
      allow(Analytics).to receive(:track)

      patch onboarding_savings_projections_path,
            params: { onboarding_savings_projection_form: { monthly_income: '', savings_rate: '20' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Analytics).to have_received(:track)
        .with(user, 'onboarding_step_failed', hash_including(step: 'savings_projection'))
    end
  end
end
