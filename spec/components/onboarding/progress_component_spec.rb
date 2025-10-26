# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::ProgressComponent, type: :component do
  it 'renders financial goal step with correct percentage' do
    rendered = render_inline(described_class.new(current_step: :financial_goal))
    expect(rendered.to_html).to include('33%')
    expect(rendered.css('.progress-fill').first['style']).to include('33')
  end

  it 'renders profile setup step with correct percentage' do
    rendered = render_inline(described_class.new(current_step: :profile_setup))
    expect(rendered.css('.progress-fill').first['style']).to include('67')
  end

  it 'renders account setup step with correct percentage' do
    rendered = render_inline(described_class.new(current_step: :account_setup))
    expect(rendered.css('.progress-fill').first['style']).to include('100')
  end

  it 'falls back to 0% for unknown step' do
    rendered = render_inline(described_class.new(current_step: :foo))
    expect(rendered.css('.progress-fill').first['style']).to include('0')
  end

  it 'applies active class to current step' do
    rendered = render_inline(described_class.new(current_step: :profile_setup))
    active = rendered.css('.step.active').text
    expect(active).to match(/Profile Setup/i)
  end
end
