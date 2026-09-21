# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::StepHeaderComponent, type: :component do
  it 'names the step and fills one segment per step reached' do
    page = render_inline(described_class.new(step: 2, title: 'Ton profil'))

    expect(page.at_css('h1').text).to eq('Ton profil')
    expect(page.text).to include(I18n.t('onboarding.step_header_component.step', step: 2, total: 3))
    expect(page.css('.onboarding-step-header__segment').size).to eq(3)
    expect(page.css('.onboarding-step-header__segment.is-done').size).to eq(2)
    expect(page.at_css('[role="progressbar"]')['aria-valuenow']).to eq('2')
  end
end
