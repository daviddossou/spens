# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::Goals::GridComponent, type: :component do
  let(:form) { mock_form_builder }

  class FakeGoalModelForGrid
    attr_reader :financial_goals
    def initialize(goals, selected)
      @goals = goals
      @financial_goals = selected
    end
    def available_goals
      @goals
    end
  end

  let(:goals) do
    [
      { key: 'save_for_emergency', name: 'Emergency Fund', description: 'Safety net' },
      { key: 'pay_off_debt', name: 'Debt Paydown', description: 'Reduce liabilities' }
    ]
  end

  it 'renders all goal cards' do
    model = FakeGoalModelForGrid.new(goals, [])
    rendered = render_inline(described_class.new(form_builder: form, model: model))
    expect(rendered.css('.card').length).to eq(2)
  end
end
