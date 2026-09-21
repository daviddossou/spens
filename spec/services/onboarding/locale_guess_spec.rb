# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::LocaleGuess do
  def guess(headers: {}, **options)
    described_class.new(request: instance_double(ActionDispatch::Request, headers: headers), **options)
  end

  it 'prefers the country picked on the landing page' do
    result = guess(headers: { 'CF-IPCountry' => 'FR' }, picked_country: 'bj', picked_currency: 'XOF')

    expect(result.country).to eq('BJ')
    expect(result.currency).to eq('XOF')
  end

  it 'falls back to the Cloudflare country and its currency' do
    result = guess(headers: { 'CF-IPCountry' => 'CM' })

    expect(result.country).to eq('CM')
    expect(result.currency).to eq('XAF')
  end

  it 'ignores Cloudflare placeholders such as XX and T1' do
    expect(guess(headers: { 'CF-IPCountry' => 'XX' }).country).to be_nil
    expect(guess(headers: { 'CF-IPCountry' => 'T1' }).country).to be_nil
  end

  it 'falls back to a time zone that belongs to one country' do
    result = guess(time_zone: 'Africa/Porto-Novo')

    expect(result.country).to eq('BJ')
    expect(result.currency).to eq('XOF')
  end

  it 'guesses nothing from an unknown time zone or an unknown currency' do
    expect(guess(time_zone: 'Mars/Olympus').country).to be_nil
    expect(guess(picked_currency: 'ZZZ').currency).to be_nil
  end
end
