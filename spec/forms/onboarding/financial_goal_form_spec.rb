# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::FinancialGoalForm, type: :model do
  let(:user) { create(:user, onboarding_current_step: :onboarding_financial_goal) }
  let(:valid_goals) { ['save_for_emergency', 'save_for_retirement'] }
  let(:form) { described_class.new(user, { financial_goals: valid_goals }) }

  describe 'inheritance' do
    it 'inherits from BaseForm' do
      expect(described_class.superclass).to eq(BaseForm)
    end
  end

  describe 'constants' do
    it 'defines CURRENT_STEP' do
      expect(described_class::CURRENT_STEP).to eq('onboarding_financial_goal')
    end

    it 'defines NEXT_STEP' do
      expect(described_class::NEXT_STEP).to eq('onboarding_profile_setup')
    end
  end

  describe '#initialize' do
    context 'with financial_goals in payload' do
      it 'sets financial_goals from payload' do
        form = described_class.new(user, { financial_goals: ['save_for_retirement'] })
        expect(form.financial_goals).to eq(['save_for_retirement'])
      end
    end

    context 'without financial_goals in payload' do
      it 'sets financial_goals from user' do
        user.update!(financial_goals: ['save_for_house'])
        form = described_class.new(user, {})
        expect(form.financial_goals).to eq(['save_for_house'])
      end
    end

    context 'when user has nil onboarding_current_step' do
      let(:user) { create(:user, onboarding_current_step: nil) }

      it 'sets onboarding_current_step to CURRENT_STEP' do
        described_class.new(user)
        expect(user.onboarding_current_step).to eq('onboarding_financial_goal')
      end
    end

    context 'when user already has onboarding_current_step' do
      it 'does not change existing onboarding_current_step' do
        user.onboarding_current_step = 'onboarding_profile_setup'
        described_class.new(user)
        expect(user.onboarding_current_step).to eq('onboarding_profile_setup')
      end
    end

    it 'sets the user attribute' do
      form = described_class.new(user)
      expect(form.user).to eq(user)
    end
  end

  describe 'validations' do
    context 'financial_goals presence' do
      it 'is invalid without financial_goals' do
        form = described_class.new(user, { financial_goals: nil })
        expect(form).not_to be_valid
        expect(form.errors[:financial_goals]).to include("can't be blank")
      end

      it 'is invalid with empty financial_goals' do
        form = described_class.new(user, { financial_goals: [] })
        expect(form).not_to be_valid
        expect(form.errors[:financial_goals]).to include("can't be blank")
      end

      it 'is valid with financial_goals present' do
        form = described_class.new(user, { financial_goals: ['save_for_retirement'] })
        expect(form).to be_valid
      end
    end

    context 'goals_are_allowed validation' do
      it 'is valid with allowed goals' do
        User::FINANCIAL_GOALS.each do |goal|
          form = described_class.new(user, { financial_goals: [goal] })
          expect(form).to be_valid
        end
      end

      it 'is invalid with disallowed goals' do
        form = described_class.new(user, { financial_goals: ['invalid_goal'] })
        expect(form).not_to be_valid
        expect(form.errors[:financial_goals]).to be_present
      end

      it 'is invalid with mix of valid and invalid goals' do
        form = described_class.new(user, { financial_goals: ['save_for_retirement', 'invalid_goal'] })
        expect(form).not_to be_valid
        expect(form.errors[:financial_goals]).to be_present
      end

      it 'adds error message with invalid goal names' do
        form = described_class.new(user, { financial_goals: ['bad_goal', 'worse_goal'] })
        form.valid?
        error_message = form.errors[:financial_goals].first
        expect(error_message).to include('bad_goal')
        expect(error_message).to include('worse_goal')
      end
    end
  end

  describe '#submit' do
    context 'when form is valid' do
      let(:form) { described_class.new(user, { financial_goals: ['save_for_retirement', 'save_for_emergency'] }) }

      it 'returns true' do
        expect(form.submit).to be true
      end

      it 'updates user financial_goals' do
        form.submit
        expect(user.reload.financial_goals).to contain_exactly('save_for_retirement', 'save_for_emergency')
      end

      it 'updates user onboarding_current_step to NEXT_STEP' do
        form.submit
        expect(user.reload.onboarding_current_step).to eq('onboarding_profile_setup')
      end

      it 'saves the user to the database' do
        expect { form.submit }.to change { user.reload.updated_at }
      end
    end

    context 'when form is invalid' do
      let(:form) { described_class.new(user, { financial_goals: nil }) }

      it 'returns false' do
        expect(form.submit).to be false
      end

      it 'does not update the user' do
        expect { form.submit }.not_to change { user.reload.updated_at }
      end

      it 'does not change financial_goals' do
        original_goals = user.financial_goals
        form.submit
        expect(user.reload.financial_goals).to eq(original_goals)
      end
    end

    context 'when user is invalid' do
      before do
        # Make the user invalid after assignment (e.g., due to country requirement)
        allow(user).to receive(:assign_attributes) do |attrs|
          user.onboarding_current_step = attrs[:onboarding_current_step]
        end
        allow(user).to receive(:valid?).and_return(false)
        allow(user).to receive(:errors).and_return(
          instance_double(ActiveModel::Errors, messages: { country: ['is required for this step'] })
        )
      end

      it 'returns false' do
        expect(form.submit).to be false
      end

      it 'promotes user errors to form errors' do
        form.submit
        expect(form.errors[:country]).to include('is required for this step')
      end

      it 'does not save the user' do
        expect(user).not_to receive(:save!)
        form.submit
      end
    end

    context 'when save raises an error' do
      before do
        # Use a real valid form but force save! to raise an error
        allow(user).to receive(:assign_attributes).and_call_original
        allow(user).to receive(:valid?).and_return(true)
        allow(user).to receive(:save!).and_raise(StandardError.new('Database error'))
      end

      it 'returns false' do
        expect(form.submit).to be false
      end

      it 'adds error to base' do
        form.submit
        expect(form.errors[:base]).to include('Database error')
      end

      it 'rescues the exception' do
        expect { form.submit }.not_to raise_error
      end
    end
  end

  describe '#available_goals' do
    it 'returns an array of goal hashes' do
      goals = form.available_goals
      expect(goals).to be_an(Array)
      expect(goals.first).to be_a(Hash)
    end

    it 'includes all goals from User::FINANCIAL_GOALS' do
      goals = form.available_goals
      goal_keys = goals.map { |g| g[:key] }
      expect(goal_keys).to match_array(User::FINANCIAL_GOALS)
    end

    it 'includes key, name, and description for each goal' do
      goal = form.available_goals.first
      expect(goal).to have_key(:key)
      expect(goal).to have_key(:name)
      expect(goal).to have_key(:description)
    end

    it 'translates goal names using I18n' do
      goal_key = User::FINANCIAL_GOALS.first
      allow(I18n).to receive(:t).and_call_original
      expect(I18n).to receive(:t).with(
        "financial_goals.#{goal_key}.name",
        default: goal_key.humanize
      ).and_call_original

      form.available_goals
    end

    it 'translates goal descriptions using I18n' do
      goal_key = User::FINANCIAL_GOALS.first
      allow(I18n).to receive(:t).and_call_original
      expect(I18n).to receive(:t).with(
        "financial_goals.#{goal_key}.description",
        default: ""
      ).and_call_original

      form.available_goals
    end

    it 'falls back to humanized name if translation is missing' do
      allow(I18n).to receive(:t).and_call_original
      goals = form.available_goals

      expect(goals.first[:name]).to be_present
    end
  end

  describe 'integration with user model' do
    it 'successfully completes the onboarding step' do
      form = described_class.new(user, { financial_goals: ['save_for_retirement'] })

      expect {
        form.submit
      }.to change { user.reload.onboarding_current_step }
        .from('onboarding_financial_goal')
        .to('onboarding_profile_setup')
    end

    it 'persists multiple financial goals' do
      goals = ['save_for_retirement', 'save_for_emergency', 'save_for_house']
      form = described_class.new(user, { financial_goals: goals })

      form.submit
      expect(user.reload.financial_goals).to match_array(goals)
    end
  end
end
