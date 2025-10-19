# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::Goals::GoalCardComponent, type: :component do
  let(:goal) { { key: 'build_wealth', name: 'Build Wealth', description: 'Increase net worth' } }
  let(:form) { mock_form_builder }

  class FakeGoalModel
    attr_reader :financial_goals
    def initialize(selected)
      @financial_goals = selected
    end
  end

  it 'marks card selected when goal included' do
    model = FakeGoalModel.new(['build_wealth'])
    rendered = render_inline(described_class.new(item: goal, form: form, model: model))
    expect(rendered.css('.card.selected')).to be_present
  end

  it 'is not selected when goal absent' do
    model = FakeGoalModel.new([])
    rendered = render_inline(described_class.new(item: goal, form: form, model: model))
    expect(rendered.css('.card.selected')).to be_empty
  end

  it 'renders goal name & description' do
    model = FakeGoalModel.new([])
    rendered = render_inline(described_class.new(item: goal, form: form, model: model))
    expect(rendered.to_html).to include('Build Wealth')
    expect(rendered.to_html).to include('Increase net worth')
  end
end
