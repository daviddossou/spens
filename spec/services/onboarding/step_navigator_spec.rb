# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::StepNavigator do
  let(:user) { create(:user, onboarding_current_step: :onboarding_financial_goal) }
  let(:navigator) { described_class.new(user) }

  describe 'constants' do
    it 'defines STEP_PATHS' do
      expect(described_class::STEP_PATHS).to be_a(Hash)
      expect(described_class::STEP_PATHS).to be_frozen
    end

    it 'maps onboarding_financial_goal to personal info path' do
      expect(described_class::STEP_PATHS['onboarding_financial_goal']).to eq(:onboarding_personal_info_path)
    end

    it 'maps onboarding_personal_info to account setup path' do
      expect(described_class::STEP_PATHS['onboarding_personal_info']).to eq(:onboarding_account_setup_path)
    end

    it 'maps onboarding_account_setup to dashboard path' do
      expect(described_class::STEP_PATHS['onboarding_account_setup']).to eq(:dashboard_path)
    end
  end

  describe '#initialize' do
    it 'accepts a user parameter' do
      expect { described_class.new(user) }.not_to raise_error
    end

    it 'sets the user instance variable' do
      navigator = described_class.new(user)
      expect(navigator.instance_variable_get(:@user)).to eq(user)
    end
  end

  describe '#next_step_path' do
    context 'when current step is onboarding_financial_goal' do
      let(:user) { create(:user, onboarding_current_step: :onboarding_financial_goal) }

      it 'returns personal info path' do
        expect(navigator.next_step_path).to eq(Rails.application.routes.url_helpers.onboarding_personal_info_path)
      end
    end

    context 'when current step is onboarding_personal_info' do
      let(:user) { create(:user, onboarding_current_step: :onboarding_personal_info) }

      it 'returns account setup path' do
        expect(navigator.next_step_path).to eq(Rails.application.routes.url_helpers.onboarding_account_setup_path)
      end
    end

    context 'when current step is onboarding_account_setup' do
      let(:user) { create(:user, onboarding_current_step: :onboarding_account_setup, country: 'BJ') }

      it 'returns dashboard path' do
        expect(navigator.next_step_path).to eq(Rails.application.routes.url_helpers.dashboard_path)
      end
    end

    context 'when current step is onboarding_completed' do
      let(:user) { create(:user, onboarding_current_step: :onboarding_completed, country: 'BJ') }

      it 'returns dashboard path' do
        expect(navigator.next_step_path).to eq(Rails.application.routes.url_helpers.dashboard_path)
      end
    end

    context 'when current step is not in STEP_PATHS' do
      before do
        allow(user).to receive(:onboarding_current_step).and_return('unknown_step')
      end

      it 'returns dashboard path as fallback' do
        expect(navigator.next_step_path).to eq(Rails.application.routes.url_helpers.dashboard_path)
      end
    end

    context 'when current step is nil' do
      before do
        allow(user).to receive(:onboarding_current_step).and_return(nil)
      end

      it 'returns dashboard path as fallback' do
        expect(navigator.next_step_path).to eq(Rails.application.routes.url_helpers.dashboard_path)
      end
    end
  end

  describe 'integration with Rails routes' do
    it 'uses Rails route helpers' do
      expect(Rails.application.routes.url_helpers).to receive(:onboarding_personal_info_path)
      navigator.next_step_path
    end

    it 'returns valid route paths' do
      path = navigator.next_step_path
      expect(path).to be_a(String)
      expect(path).to start_with('/')
    end
  end

  describe 'onboarding flow progression' do
    it 'progresses through all onboarding steps in order' do
      # Step 1: Financial Goals -> Personal Info
      user.update!(onboarding_current_step: :onboarding_financial_goal)
      navigator = described_class.new(user)
      expect(navigator.next_step_path).to include('personal_info')

      # Step 2: Personal Info -> Account Setup
      user.update!(onboarding_current_step: :onboarding_personal_info)
      navigator = described_class.new(user)
      expect(navigator.next_step_path).to include('account_setup')

      # Step 3: Account Setup -> Dashboard
      user.update!(onboarding_current_step: :onboarding_account_setup, country: 'US')
      navigator = described_class.new(user)
      expect(navigator.next_step_path).to include('dashboard')
    end
  end
end
