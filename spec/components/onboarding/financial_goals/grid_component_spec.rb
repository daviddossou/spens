# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::FinancialGoals::GridComponent, type: :component do
  let(:form) { mock_form_builder }

  it 'renders all goal cards' do
    user = User.new(financial_goals: [])
    form_object = Onboarding::FinancialGoalForm.new(user)

    rendered = render_inline(described_class.new(form_builder: form, model: form_object))

    # Should render one card for each available goal
    expect(rendered.css('.card').length).to eq(form_object.available_goals.length)
  end

  it 'marks selected goals as selected' do
    user = User.new(financial_goals: ['save_for_emergency'])
    form_object = Onboarding::FinancialGoalForm.new(user)

    rendered = render_inline(described_class.new(form_builder: form, model: form_object))

    # At least one card should be selected
    expect(rendered.css('.card.selected')).to be_present
  end
end
