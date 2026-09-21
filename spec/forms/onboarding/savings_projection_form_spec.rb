# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::SavingsProjectionForm do
  let(:user) { create(:user, onboarding_current_step: 'onboarding_savings_projection') }
  let(:space) { user.spaces.first.tap { |s| s.update_columns(country: nil) } }
  let(:guess) { instance_double(Onboarding::LocaleGuess, country: 'CM', currency: 'XAF') }

  describe 'defaults' do
    it 'opens on the example income and rate' do
      form = described_class.new(space)

      expect(form.monthly_income).to eq(150_000)
      expect(form.savings_rate).to eq(10)
      expect(form.monthly_saving).to eq(15_000)
    end

    it 'reopens on what the space already answered' do
      space.update!(monthly_income: 80_000, savings_rate: 25)

      form = described_class.new(space)

      expect(form.monthly_income).to eq(80_000)
      expect(form.savings_rate).to eq(25)
    end
  end

  describe '#currency' do
    it 'shows the guessed currency while the space has no country' do
      expect(described_class.new(space, {}, guess: guess).currency).to eq('XAF')
    end

    it 'keeps the currency of a space that already has a country' do
      space.update!(country: 'BJ', currency: 'XOF')

      expect(described_class.new(space, {}, guess: guess).currency).to eq('XOF')
    end
  end

  describe '#submit' do
    it 'saves the answers, reads a grouped amount and moves to the next step' do
      form = described_class.new(space, { monthly_income: "200 000", savings_rate: '15' })

      expect(form.submit).to be_truthy
      expect(space.reload).to have_attributes(monthly_income: 200_000, savings_rate: 15,
                                              onboarding_current_step: 'onboarding_account_setup')
    end

    it 'stores the guessed country and currency on a space without a country' do
      described_class.new(space, { monthly_income: '100000', savings_rate: '10' }, guess: guess).submit

      expect(space.reload).to have_attributes(country: 'CM', currency: 'XAF')
    end

    it 'never overwrites the country of a space that has one' do
      space.update!(country: 'BJ', currency: 'XOF')

      described_class.new(space, { monthly_income: '100000', savings_rate: '10' }, guess: guess).submit

      expect(space.reload).to have_attributes(country: 'BJ', currency: 'XOF')
    end

    it 'rejects a missing income' do
      form = described_class.new(space, { monthly_income: '', savings_rate: '10' })

      expect(form.submit).to be(false)
      expect(form.errors[:monthly_income]).to be_present
    end

    it 'rejects a rate outside the slider' do
      form = described_class.new(space, { monthly_income: '100000', savings_rate: '60' })

      expect(form.submit).to be(false)
      expect(form.errors[:savings_rate]).to be_present
    end
  end
end
