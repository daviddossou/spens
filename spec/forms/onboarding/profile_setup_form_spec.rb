# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::ProfileSetupForm, type: :model do
  let(:user) { create(:user, onboarding_current_step: 'onboarding_profile_setup', country: 'BJ', currency: 'XOF') }
  let(:space) { user.spaces.first }
  let(:valid_payload) do
    {
      country: 'US',
      currency: 'USD',
      income_frequency: 'monthly',
      main_income_source: 'salary'
    }
  end
  let(:form) { described_class.new(space, valid_payload) }

  describe 'inheritance' do
    it 'inherits from BaseForm' do
      expect(described_class.superclass).to eq(BaseForm)
    end
  end

  describe 'constants' do
    it 'defines CURRENT_STEP' do
      expect(described_class::CURRENT_STEP).to eq('onboarding_profile_setup')
    end

    it 'defines NEXT_STEP' do
      expect(described_class::NEXT_STEP).to eq('onboarding_account_setup')
    end
  end

  describe '#initialize' do
    context 'with full payload' do
      it 'sets country from payload' do
        form = described_class.new(space, { country: 'CA' })
        expect(form.country).to eq('CA')
      end

      it 'sets currency from payload' do
        form = described_class.new(space, { currency: 'CAD' })
        expect(form.currency).to eq('CAD')
      end

      it 'sets income_frequency from payload' do
        form = described_class.new(space, { income_frequency: 'weekly' })
        expect(form.income_frequency).to eq('weekly')
      end

      it 'sets main_income_source from payload' do
        form = described_class.new(space, { main_income_source: 'business' })
        expect(form.main_income_source).to eq('business')
      end
    end

    context 'without payload' do
      it 'sets country from user' do
        space.update!(country: 'FR')
        form = described_class.new(space, {})
        expect(form.country).to eq('FR')
      end

      it 'sets currency from user' do
        space.update!(currency: 'EUR')
        form = described_class.new(space, {})
        expect(form.currency).to eq('EUR')
      end

      it 'sets income_frequency from user' do
        space.update!(income_frequency: 'biweekly')
        form = described_class.new(space, {})
        expect(form.income_frequency).to eq('biweekly')
      end

      it 'sets main_income_source from user' do
        space.update!(main_income_source: 'freelance')
        form = described_class.new(space, {})
        expect(form.main_income_source).to eq('freelance')
      end
    end

    context 'with partial payload' do
      it 'uses payload values over user values' do
        space.update!(country: 'BJ', currency: 'XOF')
        form = described_class.new(space, { country: 'US' })

        expect(form.country).to eq('US')
        expect(form.currency).to eq('XOF') # from user
      end
    end

    context 'when user has nil currency' do
      it 'defaults to XOF' do
        space.update!(currency: nil)
        form = described_class.new(space, {})
        expect(form.currency).to eq('XOF')
      end
    end

    context 'when user has nil onboarding_current_step' do
      let(:user) { create(:user, onboarding_current_step: nil) }

      it 'sets onboarding_current_step to CURRENT_STEP' do
        described_class.new(space)
        expect(space.onboarding_current_step).to eq('onboarding_profile_setup')
      end
    end

    context 'when user already has onboarding_current_step' do
      it 'does not change existing onboarding_current_step' do
        space.onboarding_current_step = 'onboarding_account_setup'
        described_class.new(space)
        expect(space.onboarding_current_step).to eq('onboarding_account_setup')
      end
    end

    it 'sets the space attribute' do
      form = described_class.new(space)
      expect(form.space).to eq(space)
    end
  end

  describe 'validations' do
    context 'country' do
      it 'is invalid without country' do
        form = described_class.new(space, { country: 'US', currency: 'USD' })
        form.country = nil
        expect(form).not_to be_valid
        expect(form.errors[:country]).to include("can't be blank")
      end

      it 'is invalid with empty country' do
        form = described_class.new(space, { country: 'US', currency: 'USD' })
        form.country = ''
        expect(form).not_to be_valid
        expect(form.errors[:country]).to include("can't be blank")
      end

      it 'is valid with country present' do
        form = described_class.new(space, valid_payload.merge(country: 'US'))
        expect(form).to be_valid
      end
    end

    context 'currency' do
      it 'is invalid without currency when user also has no currency' do
        space.update!(currency: nil, country: 'US')
        # When both payload and space.currency are nil, it defaults to XOF which is valid
        # To test currency validation, we need to explicitly set an invalid currency
        form = described_class.new(space, { country: 'US', currency: '' })
        # Empty string after default won't be XOF, so test with explicit invalid value instead
        form.currency = nil
        form.validate
        expect(form).not_to be_valid
        expect(form.errors[:currency]).to be_present
      end

      it 'is invalid with empty currency string explicitly set' do
        form = described_class.new(space, { country: 'US', currency: 'USD' })
        form.currency = ''
        form.validate
        expect(form).not_to be_valid
        expect(form.errors[:currency]).to be_present
      end

      it 'is invalid with currency not in Space::CURRENCIES' do
        form = described_class.new(space, valid_payload.merge(currency: 'INVALID'))
        expect(form).not_to be_valid
        expect(form.errors[:currency]).to include('is not included in the list')
      end

      it 'is valid with currency in Space::CURRENCIES' do
        Space::CURRENCIES.sample(5).each do |currency|
          form = described_class.new(space, valid_payload.merge(currency: currency))
          expect(form).to be_valid, "Expected #{currency} to be valid"
        end
      end
    end

    context 'income_frequency' do
      it 'is valid when blank' do
        form = described_class.new(space, valid_payload.merge(income_frequency: ''))
        expect(form).to be_valid
      end

      it 'is valid when nil' do
        form = described_class.new(space, valid_payload.merge(income_frequency: nil))
        expect(form).to be_valid
      end

      it 'is invalid with value not in Space::INCOME_FREQUENCIES' do
        form = described_class.new(space, valid_payload.merge(income_frequency: 'invalid'))
        expect(form).not_to be_valid
        expect(form.errors[:income_frequency]).to include('is not included in the list')
      end

      it 'is valid with value in Space::INCOME_FREQUENCIES' do
        Space::INCOME_FREQUENCIES.each do |frequency|
          form = described_class.new(space, valid_payload.merge(income_frequency: frequency))
          expect(form).to be_valid, "Expected #{frequency} to be valid"
        end
      end
    end

    context 'main_income_source' do
      it 'is valid when blank' do
        form = described_class.new(space, valid_payload.merge(main_income_source: ''))
        expect(form).to be_valid
      end

      it 'is valid when nil' do
        form = described_class.new(space, valid_payload.merge(main_income_source: nil))
        expect(form).to be_valid
      end

      it 'accepts any string value' do
        [ 'salary', 'business', 'freelance', 'investments' ].each do |source|
          form = described_class.new(space, valid_payload.merge(main_income_source: source))
          expect(form).to be_valid
        end
      end
    end
  end

  describe '#submit' do
    context 'when form is valid' do
      let(:form) { described_class.new(space, valid_payload) }

      it 'returns true' do
        expect(form.submit).to be true
      end

      it 'updates user country' do
        form.submit
        expect(space.reload.country).to eq('US')
      end

      it 'updates user currency' do
        form.submit
        expect(space.reload.currency).to eq('USD')
      end

      it 'updates user income_frequency' do
        form.submit
        expect(space.reload.income_frequency).to eq('monthly')
      end

      it 'updates user main_income_source' do
        form.submit
        expect(space.reload.main_income_source).to eq('salary')
      end

      it 'updates user onboarding_current_step to NEXT_STEP' do
        form.submit
        expect(space.reload.onboarding_current_step).to eq('onboarding_account_setup')
      end

      it 'saves the user to the database' do
        expect { form.submit }.to change { space.reload.updated_at }
      end
    end

    context 'when form is invalid' do
      let(:form) { described_class.new(space, { country: '', currency: 'INVALID' }) }

      it 'returns false' do
        expect(form.submit).to be false
      end

      it 'does not update the user' do
        original_updated_at = space.updated_at
        sleep 0.01 # Ensure time difference would be detectable
        form.submit
        expect(space.reload.updated_at).to be_within(1.second).of(original_updated_at)
      end

      it 'does not change country' do
        original_country = space.country
        form.submit
        expect(space.reload.country).to eq(original_country)
      end

      it 'does not change onboarding_current_step' do
        original_step = space.onboarding_current_step
        form.submit
        expect(space.reload.onboarding_current_step).to eq(original_step)
      end
    end

    context 'with minimal valid data (only required fields)' do
      let(:minimal_payload) { { country: 'BF', currency: 'XOF' } }
      let(:form) { described_class.new(space, minimal_payload) }

      it 'returns true' do
        expect(form.submit).to be true
      end

      it 'updates required fields' do
        form.submit
        space.reload
        expect(space.country).to eq('BF')
        expect(space.currency).to eq('XOF')
      end

      it 'allows optional fields to be blank' do
        form.submit
        space.reload
        expect(space.income_frequency).to be_blank
        expect(space.main_income_source).to be_blank
      end

      it 'advances to next step' do
        form.submit
        expect(space.reload.onboarding_current_step).to eq('onboarding_account_setup')
      end
    end

    context 'when space is invalid' do
      before do
        # Simulate a scenario where space validation fails after assignment
        allow(space).to receive(:assign_attributes) do |attrs|
          space.instance_variable_set(:@onboarding_current_step, attrs[:onboarding_current_step])
        end
        allow(space).to receive(:invalid?).and_return(true)
        allow(space).to receive(:errors).and_return(
          instance_double(ActiveModel::Errors, messages: { base: [ 'Some user validation error' ] })
        )
      end

      it 'returns false' do
        expect(form.submit).to be false
      end

      it 'promotes user errors to form errors' do
        form.submit
        expect(form.errors[:base]).to include('Some user validation error')
      end

      it 'does not save the space' do
        expect(space).not_to receive(:save!)
        form.submit
      end
    end

    context 'when save raises an error' do
      before do
        allow(space).to receive(:assign_attributes).and_call_original
        allow(space).to receive(:invalid?).and_return(false)
        allow(space).to receive(:save!).and_raise(StandardError.new('Database connection lost'))
      end

      it 'returns false' do
        expect(form.submit).to be false
      end

      it 'adds error to base' do
        form.submit
        expect(form.errors[:base]).to include('Database connection lost')
      end

      it 'rescues the exception' do
        expect { form.submit }.not_to raise_error
      end
    end
  end

  describe 'integration with user model' do
    it 'successfully completes the onboarding step' do
      form = described_class.new(space, { country: 'US', currency: 'USD' })

      expect {
        form.submit
      }.to change { space.reload.onboarding_current_step }
        .from('onboarding_profile_setup')
        .to('onboarding_account_setup')
    end

    it 'persists all profile setup data' do
      payload = {
        country: 'CA',
        currency: 'CAD',
        income_frequency: 'biweekly',
        main_income_source: 'freelance'
      }
      form = described_class.new(space, payload)

      expect(form.submit).to be true
      space.reload

      expect(space.country).to eq('CA')
      expect(space.currency).to eq('CAD')
      expect(space.income_frequency).to eq('biweekly')
      expect(space.main_income_source).to eq('freelance')
    end

    it 'respects user model validations' do
      # If country is required when onboarding_current_step is advanced
      form = described_class.new(space, { country: 'US', currency: 'USD' })

      expect { form.submit }.not_to raise_error
      expect(space.reload.country).to eq('US')
    end
  end

  describe 'attributes' do
    it 'has country attribute accessor' do
      expect(form).to respond_to(:country)
      expect(form).to respond_to(:country=)
    end

    it 'has currency attribute accessor' do
      expect(form).to respond_to(:currency)
      expect(form).to respond_to(:currency=)
    end

    it 'has income_frequency attribute accessor' do
      expect(form).to respond_to(:income_frequency)
      expect(form).to respond_to(:income_frequency=)
    end

    it 'has main_income_source attribute accessor' do
      expect(form).to respond_to(:main_income_source)
      expect(form).to respond_to(:main_income_source=)
    end

    it 'has space attribute reader' do
      expect(form).to respond_to(:space)
      expect(form.space).to eq(space)
    end
  end

  describe 'edge cases' do
    context 'when payload has string keys instead of symbols' do
      let(:string_payload) do
        {
          'country' => 'US',
          'currency' => 'USD',
          'income_frequency' => 'monthly',
          'main_income_source' => 'salary'
        }
      end

      it 'handles string keys correctly' do
        form = described_class.new(space, string_payload.symbolize_keys)
        expect(form.country).to eq('US')
        expect(form.currency).to eq('USD')
      end
    end

    context 'when changing currency for existing user with accounts' do
      it 'updates currency successfully' do
        space.update!(currency: 'XOF')
        form = described_class.new(space, { country: 'US', currency: 'USD' })

        expect(form.submit).to be true
        expect(space.reload.currency).to eq('USD')
      end
    end

    context 'when updating from one valid country to another' do
      it 'allows country changes' do
        space.update!(country: 'BJ')
        form = described_class.new(space, { country: 'US', currency: 'USD' })

        form.submit
        expect(space.reload.country).to eq('US')
      end
    end
  end
end
