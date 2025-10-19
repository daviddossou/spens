# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ui::SelectableCardComponent, type: :component do
  let(:item) { { key: 'test', name: 'Test Item', description: 'Test Description' } }

  describe 'basic rendering without form' do
    it 'renders item without checkbox when no form provided' do
      rendered = render_inline(described_class.new(item: item))
      expect(rendered.to_html).to include('Test Item')
      expect(rendered.to_html).to include('Test Description')
      expect(rendered.css('input[type="checkbox"]')).to be_empty
    end
  end

  describe 'with custom css_class' do
    it 'uses custom css class' do
      rendered = render_inline(described_class.new(item: item, css_class: 'custom-card'))
      expect(rendered.css('.custom-card')).to be_present
    end
  end

  describe 'selected state' do
    it 'adds selected class when selected is true' do
      rendered = render_inline(described_class.new(item: item, selected: true, css_class: 'test-card'))
      expect(rendered.css('.test-card.selected')).to be_present
    end

    it 'does not add selected class when selected is false' do
      rendered = render_inline(described_class.new(item: item, selected: false, css_class: 'test-card'))
      expect(rendered.css('.test-card.selected')).to be_empty
      expect(rendered.css('.test-card')).to be_present
    end
  end

  describe 'data attributes' do
    it 'adds custom data attributes when provided' do
      rendered = render_inline(described_class.new(
        item: item,
        data: {
          'test-target': 'card',
          action: 'click->test-controller#toggle',
          value: 'test-value'
        }
      ))

      root_element = rendered.css('div').first
      expect(root_element['data-test-target']).to eq('card')
      expect(root_element['data-action']).to eq('click->test-controller#toggle')
      expect(root_element['data-value']).to eq('test-value')
    end
  end

  describe 'with form integration' do
    let(:form) { mock_form_builder }

    it 'renders checkbox when form and field provided' do
      rendered = render_inline(described_class.new(
        item: item,
        form: form,
        field: :test_field,
        selected: true
      ))

      checkbox = rendered.css('input[type="checkbox"]').first
      expect(checkbox).to be_present
      expect(checkbox['checked']).to eq('checked')
    end
  end

  describe 'visual checkbox' do
    it 'shows visual checkbox only when selected and show_visual_checkbox is true' do
      rendered = render_inline(described_class.new(
        item: item,
        selected: true,
        show_visual_checkbox: true
      ))

      visual_checkbox = rendered.css('.card-checkbox').first
      expect(visual_checkbox).to be_present
    end

    it 'hides visual checkbox when not selected' do
      rendered = render_inline(described_class.new(
        item: item,
        selected: false,
        show_visual_checkbox: true
      ))

      visual_checkbox = rendered.css('.card-checkbox').first
      expect(visual_checkbox).to be_present
    end

    it 'hides visual checkbox when show_visual_checkbox is false' do
      rendered = render_inline(described_class.new(
        item: item,
        selected: true,
        show_visual_checkbox: false
      ))

      visual_checkbox = rendered.css('.card-checkbox').first
      expect(visual_checkbox).to be_nil
    end

    it 'includes checkmark SVG inside visual checkbox when rendered' do
      rendered = render_inline(described_class.new(
        item: item,
        selected: true,
        show_visual_checkbox: true
      ))

      checkmark = rendered.css('.card-checkbox .checkmark').first
      expect(checkmark).to be_present
      expect(checkmark.name).to eq('svg')
    end
  end
end
