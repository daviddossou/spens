# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ui::SelectableCardComponent, type: :component do
  let(:item) { { key: 'test', name: 'Test Item', description: 'Test Description' } }
  let(:form) { mock_form_builder }

  describe 'basic rendering' do
    it 'renders item name and description' do
      rendered = render_inline(described_class.new(item: item, form: form, field: :test_field))
      expect(rendered.to_html).to include('Test Item')
      expect(rendered.to_html).to include('Test Description')
    end

    it 'always renders a checkbox since it is selectable' do
      rendered = render_inline(described_class.new(item: item, form: form, field: :test_field))
      expect(rendered.css('input[type="checkbox"]')).to be_present
    end
  end

  describe 'with custom css_class' do
    it 'uses custom css class' do
      rendered = render_inline(described_class.new(item: item, form: form, field: :test_field, css_class: 'custom-card'))
      expect(rendered.css('.custom-card')).to be_present
    end
  end

  describe 'selected state' do
    it 'adds selected class when selected is true' do
      rendered = render_inline(described_class.new(item: item, form: form, field: :test_field, selected: true, css_class: 'test-card'))
      expect(rendered.css('.test-card.selected')).to be_present
    end

    it 'does not add selected class when selected is false' do
      rendered = render_inline(described_class.new(item: item, form: form, field: :test_field, selected: false, css_class: 'test-card'))
      expect(rendered.css('.test-card.selected')).to be_empty
      expect(rendered.css('.test-card')).to be_present
    end
  end

  describe 'data attributes' do
    it 'adds custom data attributes and merges with auto-added Stimulus attributes' do
      rendered = render_inline(described_class.new(
        item: item,
        form: form,
        field: :test_field,
        data: {
          'test-target': 'card',
          action: 'click->test-controller#toggle',
          value: 'test-value'
        }
      ))

      root_element = rendered.css('div').first
      expect(root_element['data-test-target']).to eq('card')
      expect(root_element['data-action']).to include('click->test-controller#toggle')
      expect(root_element['data-action']).to include('click->ui--selectable-card#toggle')
      expect(root_element['data-value']).to eq('test-value')
    end
  end

  describe 'with form integration' do
    it 'always renders checkbox' do
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

    it 'automatically adds ui--selectable-card controller' do
      rendered = render_inline(described_class.new(
        item: item,
        form: form,
        field: :test_field
      ))

      root_element = rendered.css('div').first
      expect(root_element['data-controller']).to include('ui--selectable-card')
    end

    it 'automatically adds toggle action' do
      rendered = render_inline(described_class.new(
        item: item,
        form: form,
        field: :test_field
      ))

      root_element = rendered.css('div').first
      expect(root_element['data-action']).to include('click->ui--selectable-card#toggle')
    end

    it 'adds checkbox target to hidden checkbox input' do
      rendered = render_inline(described_class.new(
        item: item,
        form: form,
        field: :test_field
      ))

      checkbox = rendered.css('input[type="checkbox"]').first
      expect(checkbox['data-ui--selectable-card-target']).to eq('checkbox')
    end

    it 'preserves existing data-controller attributes' do
      rendered = render_inline(described_class.new(
        item: item,
        form: form,
        field: :test_field,
        data: { controller: 'custom-controller' }
      ))

      root_element = rendered.css('div').first
      expect(root_element['data-controller']).to include('custom-controller')
      expect(root_element['data-controller']).to include('ui--selectable-card')
    end

    it 'preserves existing data-action attributes' do
      rendered = render_inline(described_class.new(
        item: item,
        form: form,
        field: :test_field,
        data: { action: 'mouseover->custom#hover' }
      ))

      root_element = rendered.css('div').first
      expect(root_element['data-action']).to include('mouseover->custom#hover')
      expect(root_element['data-action']).to include('click->ui--selectable-card#toggle')
    end
  end

  describe 'visual checkbox' do
    it 'shows visual checkbox when show_visual_checkbox is true' do
      rendered = render_inline(described_class.new(
        item: item,
        form: form,
        field: :test_field,
        selected: true,
        show_visual_checkbox: true
      ))

      visual_checkbox = rendered.css('.card-checkbox').first
      expect(visual_checkbox).to be_present
    end

    it 'renders visual checkbox even when not selected' do
      rendered = render_inline(described_class.new(
        item: item,
        form: form,
        field: :test_field,
        selected: false,
        show_visual_checkbox: true
      ))

      visual_checkbox = rendered.css('.card-checkbox').first
      expect(visual_checkbox).to be_present
    end

    it 'hides visual checkbox when show_visual_checkbox is false' do
      rendered = render_inline(described_class.new(
        item: item,
        form: form,
        field: :test_field,
        selected: true,
        show_visual_checkbox: false
      ))

      visual_checkbox = rendered.css('.card-checkbox').first
      expect(visual_checkbox).to be_nil
    end

    it 'includes checkmark SVG inside visual checkbox when rendered' do
      rendered = render_inline(described_class.new(
        item: item,
        form: form,
        field: :test_field,
        selected: true,
        show_visual_checkbox: true
      ))

      checkmark = rendered.css('.card-checkbox .checkmark').first
      expect(checkmark).to be_present
      expect(checkmark.name).to eq('svg')
    end
  end
end
