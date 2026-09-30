# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::StepNavigator do
  let(:user) { create(:user, onboarding_current_step: :onboarding_financial_goal) }
  let(:space) { user.spaces.first }
  let(:navigator) { described_class.new(space) }

  describe 'constants' do
    it 'defines STEP_PATHS' do
      expect(described_class::STEP_PATHS).to be_a(Hash)
      expect(described_class::STEP_PATHS).to be_frozen
    end

    it 'sends the retired savings projection step on to the first day' do
      expect(described_class::STEP_PATHS['onboarding_savings_projection']).to eq(:onboarding_first_days_path)
    end

    it 'sends the retired financial goal step on to the first day' do
      expect(described_class::STEP_PATHS['onboarding_financial_goal']).to eq(:onboarding_first_days_path)
    end

    it 'sends the retired profile step on to the first day' do
      expect(described_class::STEP_PATHS['onboarding_profile_setup']).to eq(:onboarding_first_days_path)
    end

    it 'maps onboarding_account_setup on to the first day' do
      expect(described_class::STEP_PATHS['onboarding_account_setup']).to eq(:onboarding_first_days_path)
    end

    it 'maps the balances and the summary to their steps' do
      expect(described_class::STEP_PATHS['onboarding_balances']).to eq(:onboarding_balances_path)
      expect(described_class::STEP_PATHS['onboarding_summary']).to eq(:onboarding_summaries_path)
    end

    it 'maps onboarding_completed to dashboard path' do
      expect(described_class::STEP_PATHS['onboarding_completed']).to eq(:dashboard_path)
    end
  end

  describe '#initialize' do
    it 'accepts a space parameter' do
      expect { described_class.new(space) }.not_to raise_error
    end

    it 'sets the space instance variable' do
      navigator = described_class.new(space)
      expect(navigator.instance_variable_get(:@space)).to eq(space)
    end
  end

  describe '#current_step_path' do
    context 'when current step is onboarding_savings_projection' do
      let(:user) { create(:user, onboarding_current_step: :onboarding_savings_projection) }

      it 'returns the first day path' do
        expect(navigator.current_step_path).to eq(Rails.application.routes.url_helpers.onboarding_first_days_path)
      end
    end

    context 'when current step is the retired onboarding_financial_goal' do
      let(:user) { create(:user, onboarding_current_step: :onboarding_financial_goal) }

      it 'returns the first day path' do
        expect(navigator.current_step_path).to eq(Rails.application.routes.url_helpers.onboarding_first_days_path)
      end
    end

    context 'when current step is onboarding_profile_setup' do
      let(:user) { create(:user, onboarding_current_step: :onboarding_profile_setup) }

      it 'returns the first day path' do
        expect(navigator.current_step_path).to eq(Rails.application.routes.url_helpers.onboarding_first_days_path)
      end
    end

    context 'when current step is onboarding_account_setup' do
      let(:user) { create(:user, onboarding_current_step: :onboarding_account_setup, country: 'BJ') }

      it 'returns the first day path' do
        expect(navigator.current_step_path).to eq(Rails.application.routes.url_helpers.onboarding_first_days_path)
      end
    end

    context 'when current step is onboarding_completed' do
      let(:user) { create(:user, onboarding_current_step: :onboarding_completed, country: 'BJ') }

      it 'returns dashboard path' do
        expect(navigator.current_step_path).to eq(Rails.application.routes.url_helpers.dashboard_path)
      end
    end

    context 'when current step is not in STEP_PATHS' do
      before do
        allow(space).to receive(:onboarding_current_step).and_return('unknown_step')
      end

      it 'returns savings projection path as fallback' do
        expect(navigator.current_step_path).to eq(Rails.application.routes.url_helpers.onboarding_first_days_path)
      end
    end

    context 'when current step is nil' do
      before do
        allow(space).to receive(:onboarding_current_step).and_return(nil)
      end

      it 'returns savings projection path as fallback' do
        expect(navigator.current_step_path).to eq(Rails.application.routes.url_helpers.onboarding_first_days_path)
      end
    end
  end

  describe 'integration with Rails routes' do
    it 'uses Rails route helpers' do
      expect(Rails.application.routes.url_helpers).to receive(:onboarding_first_days_path)
      navigator.current_step_path
    end

    it 'returns valid route paths' do
      path = navigator.current_step_path
      expect(path).to be_a(String)
      expect(path).to start_with('/')
    end
  end

  describe 'onboarding flow step mapping' do
    it 'maps the retired savings projection step to the first day' do
      space.update!(onboarding_current_step: :onboarding_savings_projection)
      navigator = described_class.new(space)
      expect(navigator.current_step_path).to include('first_days')
    end

    it 'maps the retired profile step to the first day' do
      space.update!(onboarding_current_step: :onboarding_profile_setup)
      navigator = described_class.new(space)
      expect(navigator.current_step_path).to include('first_days')
    end

    it 'maps a space parked on the account setup step to the first day' do
      space.update!(onboarding_current_step: :onboarding_account_setup, country: 'US')
      navigator = described_class.new(space)
      expect(navigator.current_step_path).to include('first_days')
    end

    it 'maps completed step to dashboard path' do
      space.update!(onboarding_current_step: :onboarding_completed, country: 'US')
      navigator = described_class.new(space)
      expect(navigator.current_step_path).to include('dashboard')
    end
  end
end
