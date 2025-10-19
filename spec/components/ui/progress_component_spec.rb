# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ui::ProgressComponent, type: :component do
  describe 'basic rendering' do
    it 'renders without any parameters' do
      rendered = render_inline(described_class.new)
      expect(rendered.to_html).to be_present
      expect(rendered.css('.progress-container')).to be_present
    end

    it 'uses default css class' do
      rendered = render_inline(described_class.new)
      expect(rendered.css('.progress-container')).to be_present
    end

    it 'uses custom css class' do
      rendered = render_inline(described_class.new(css_class: 'custom-progress'))
      expect(rendered.css('.custom-progress')).to be_present
    end
  end

  describe 'percentage calculation' do
    context 'when percentage is provided explicitly' do
      it 'uses the provided percentage' do
        component = described_class.new(
          percentage: 75,
          steps: ['step1', 'step2', 'step3'],
          current_step: 'step2'
        )
        expect(component.send(:calculated_percentage)).to eq(75)
      end
    end

    context 'when percentage is calculated from steps' do
      it 'calculates correct percentage for first step' do
        component = described_class.new(
          steps: ['step1', 'step2', 'step3'],
          current_step: 'step1'
        )
        expect(component.send(:calculated_percentage)).to eq(33)
      end

      it 'calculates correct percentage for middle step' do
        component = described_class.new(
          steps: ['step1', 'step2', 'step3'],
          current_step: 'step2'
        )
        expect(component.send(:calculated_percentage)).to eq(67)
      end

      it 'calculates correct percentage for last step' do
        component = described_class.new(
          steps: ['step1', 'step2', 'step3'],
          current_step: 'step3'
        )
        expect(component.send(:calculated_percentage)).to eq(100)
      end

      it 'returns 0 when no steps provided' do
        component = described_class.new(steps: [])
        expect(component.send(:calculated_percentage)).to eq(0)
      end

      it 'returns 0 when current_step not found in steps' do
        component = described_class.new(
          steps: ['step1', 'step2', 'step3'],
          current_step: 'unknown_step'
        )
        expect(component.send(:calculated_percentage)).to eq(0)
      end

      it 'returns 0 when current_step is nil' do
        component = described_class.new(
          steps: ['step1', 'step2', 'step3'],
          current_step: nil
        )
        expect(component.send(:calculated_percentage)).to eq(0)
      end
    end

    context 'with different step counts' do
      it 'handles single step correctly' do
        component = described_class.new(
          steps: ['only_step'],
          current_step: 'only_step'
        )
        expect(component.send(:calculated_percentage)).to eq(100)
      end

      it 'handles many steps correctly' do
        steps = (1..10).map { |i| "step#{i}" }
        component = described_class.new(
          steps: steps,
          current_step: 'step5'
        )
        expect(component.send(:calculated_percentage)).to eq(50)
      end
    end
  end

  describe 'step classes' do
    let(:steps) { ['step1', 'step2', 'step3', 'step4'] }
    let(:current_step) { 'step2' }

    let(:component) do
      described_class.new(
        steps: steps,
        current_step: current_step
      )
    end

    it 'assigns active class to current step' do
      expect(component.send(:step_classes, 'step2')).to eq('step active')
    end

    it 'assigns completed class to previous steps' do
      expect(component.send(:step_classes, 'step1')).to eq('step completed')
    end

    it 'assigns default class to future steps' do
      expect(component.send(:step_classes, 'step3')).to eq('step')
      expect(component.send(:step_classes, 'step4')).to eq('step')
    end

    it 'handles string and symbol step names consistently' do
      expect(component.send(:step_classes, :step2)).to eq('step active')
      expect(component.send(:step_classes, :step1)).to eq('step completed')
      expect(component.send(:step_classes, :step3)).to eq('step')
    end

    context 'when current_step is not in steps array' do
      let(:component) do
        described_class.new(
          steps: steps,
          current_step: 'unknown_step'
        )
      end

      it 'returns default class for all steps' do
        steps.each do |step|
          expect(component.send(:step_classes, step)).to eq('step')
        end
      end
    end
  end

  describe 'data type handling' do
    it 'converts step names to strings' do
      component = described_class.new(
        steps: [:step1, :step2, :step3],
        current_step: :step2
      )
      expect(component.send(:calculated_percentage)).to eq(67)
    end

    it 'converts current_step to string' do
      component = described_class.new(
        steps: ['step1', 'step2', 'step3'],
        current_step: :step2
      )
      expect(component.send(:calculated_percentage)).to eq(67)
    end

    it 'handles mixed string and symbol steps' do
      component = described_class.new(
        steps: [:step1, 'step2', :step3],
        current_step: 'step2'
      )
      expect(component.send(:calculated_percentage)).to eq(67)
      expect(component.send(:step_classes, 'step1')).to eq('step completed')
    end
  end

  describe 'html options' do
    it 'merges custom html options' do
      rendered = render_inline(described_class.new(
        id: 'custom-progress',
        data: {
          target: 'progress-controller',
          action: 'click->progress#update'
        },
        'aria-label': 'Progress indicator'
      ))

      container = rendered.css('.progress-container').first
      expect(container['id']).to eq('custom-progress')
      expect(container['data-target']).to eq('progress-controller')
      expect(container['data-action']).to eq('click->progress#update')
      expect(container['aria-label']).to eq('Progress indicator')
    end

    it 'preserves existing class when adding custom classes' do
      rendered = render_inline(described_class.new(
        class: 'custom-class another-class'
      ))

      container = rendered.css('.progress-container').first
      expect(container['class']).to include('progress-container')
      expect(container['class']).to include('custom-class')
      expect(container['class']).to include('another-class')
    end
  end

  describe 'configuration options' do
    it 'accepts labels option' do
      component = described_class.new(labels: false)
      expect(component.send(:labels)).to be false
    end

    it 'accepts show_bar option' do
      component = described_class.new(show_bar: false)
      expect(component.send(:show_bar)).to be false
    end

    it 'defaults labels to true' do
      component = described_class.new
      expect(component.send(:labels)).to be true
    end

    it 'defaults show_bar to true' do
      component = described_class.new
      expect(component.send(:show_bar)).to be true
    end
  end

  describe 'step labeling' do
    let(:component) { described_class.new }

    it 'humanizes step names by default' do
      expect(component.send(:step_label, 'user_info')).to eq('User info')
      expect(component.send(:step_label, 'payment_details')).to eq('Payment details')
      expect(component.send(:step_label, 'confirmation')).to eq('Confirmation')
    end

    it 'handles single word steps' do
      expect(component.send(:step_label, 'setup')).to eq('Setup')
      expect(component.send(:step_label, 'review')).to eq('Review')
    end

    it 'handles steps with numbers' do
      expect(component.send(:step_label, 'step_1')).to eq('Step 1')
      expect(component.send(:step_label, 'step_2')).to eq('Step 2')
    end
  end

  describe 'edge cases and error handling' do
    it 'handles empty step array gracefully' do
      rendered = render_inline(described_class.new(
        steps: [],
        current_step: nil
      ))
      expect(rendered.to_html).to be_present
    end

    it 'handles nil current_step gracefully' do
      rendered = render_inline(described_class.new(
        steps: ['step1', 'step2'],
        current_step: nil
      ))
      expect(rendered.to_html).to be_present
    end

    it 'handles empty string current_step' do
      component = described_class.new(
        steps: ['step1', 'step2'],
        current_step: ''
      )
      expect(component.send(:calculated_percentage)).to eq(0)
    end
  end

  describe 'integration scenarios' do
    context 'multi-step form progress' do
      let(:form_steps) { %w[personal_info address payment confirmation] }

      it 'correctly represents progress at each step' do
        # First step
        component = described_class.new(
          steps: form_steps,
          current_step: 'personal_info'
        )
        expect(component.send(:calculated_percentage)).to eq(25)
        expect(component.send(:step_classes, 'personal_info')).to eq('step active')

        # Middle step
        component = described_class.new(
          steps: form_steps,
          current_step: 'payment'
        )
        expect(component.send(:calculated_percentage)).to eq(75)
        expect(component.send(:step_classes, 'personal_info')).to eq('step completed')
        expect(component.send(:step_classes, 'address')).to eq('step completed')
        expect(component.send(:step_classes, 'payment')).to eq('step active')
        expect(component.send(:step_classes, 'confirmation')).to eq('step')
      end
    end

    context 'custom percentage override' do
      it 'allows manual percentage control regardless of step calculation' do
        component = described_class.new(
          steps: %w[step1 step2 step3 step4],
          current_step: 'step1',
          percentage: 90  # Override calculated 25%
        )
        expect(component.send(:calculated_percentage)).to eq(90)
      end
    end
  end
end
