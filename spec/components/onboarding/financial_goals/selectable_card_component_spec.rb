# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::FinancialGoals::SelectableCardComponent, type: :component do
  let(:goal) { { key: 'build_wealth', name: 'Build Wealth', description: 'Increase net worth' } }
  let(:form) { mock_form_builder }

  it 'marks card selected when goal included' do
    model = User.new(financial_goals: [ 'build_wealth' ])
    rendered = render_inline(described_class.new(item: goal, form: form, model: model))
    expect(rendered.css('.card.selected')).to be_present
  end

  it 'is not selected when goal absent' do
    model = User.new(financial_goals: [])
    rendered = render_inline(described_class.new(item: goal, form: form, model: model))
    expect(rendered.css('.card.selected')).to be_empty
  end

  it 'renders goal name & description' do
    model = User.new(financial_goals: [])
    rendered = render_inline(described_class.new(item: goal, form: form, model: model))
    expect(rendered.to_html).to include('Build Wealth')
    expect(rendered.to_html).to include('Increase net worth')
  end

  it 'inherits Stimulus controller from parent component' do
    model = User.new(financial_goals: [])
    rendered = render_inline(described_class.new(item: goal, form: form, model: model))

    root_element = rendered.css('div').first
    expect(root_element['data-controller']).to include('ui--selectable-card')
    expect(root_element['data-action']).to include('click->ui--selectable-card#toggle')
  end

  it 'adds checkbox target to form checkbox' do
    model = User.new(financial_goals: [])
    rendered = render_inline(described_class.new(item: goal, form: form, model: model))

    checkbox = rendered.css('input[type="checkbox"]').first
    expect(checkbox['data-ui--selectable-card-target']).to eq('checkbox')
  end
end
