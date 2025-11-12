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

  describe 'multiple parameter (checkbox vs radio)' do
    context 'when multiple is true (default)' do
      it 'renders checkbox input' do
        rendered = render_inline(described_class.new(
          item: item,
          form: form,
          field: :test_field,
          multiple: true
        ))

        expect(rendered.css('input[type="checkbox"]')).to be_present
        expect(rendered.css('input[type="radio"]')).to be_empty
      end

      it 'adds checkbox target to input' do
        rendered = render_inline(described_class.new(
          item: item,
          form: form,
          field: :test_field,
          multiple: true
        ))

        checkbox = rendered.css('input[type="checkbox"]').first
        expect(checkbox['data-ui--selectable-card-target']).to eq('checkbox')
      end
    end

    context 'when multiple is false' do
      it 'renders radio button input' do
        rendered = render_inline(described_class.new(
          item: item,
          form: form,
          field: :test_field,
          multiple: false
        ))

        expect(rendered.css('input[type="radio"]')).to be_present
        expect(rendered.css('input[type="checkbox"]')).to be_empty
      end

      it 'adds radio target to input' do
        rendered = render_inline(described_class.new(
          item: item,
          form: form,
          field: :test_field,
          multiple: false
        ))

        radio = rendered.css('input[type="radio"]').first
        expect(radio['data-ui--selectable-card-target']).to eq('radio')
      end

      it 'uses RadioButtonFieldComponent' do
        component = described_class.new(
          item: item,
          form: form,
          field: :test_field,
          multiple: false
        )

        expect(Forms::RadioButtonFieldComponent).to receive(:new).and_call_original
        render_inline(component)
      end
    end
  end

  describe 'compact parameter' do
    context 'when compact is true' do
      it 'adds compact class to root element' do
        rendered = render_inline(described_class.new(
          item: item,
          form: form,
          field: :test_field,
          compact: true
        ))

        expect(rendered.css('.card.compact')).to be_present
      end

      it 'combines with selected state' do
        rendered = render_inline(described_class.new(
          item: item,
          form: form,
          field: :test_field,
          compact: true,
          selected: true
        ))

        expect(rendered.css('.card.compact.selected')).to be_present
      end
    end

    context 'when compact is false (default)' do
      it 'does not add compact class' do
        rendered = render_inline(described_class.new(
          item: item,
          form: form,
          field: :test_field,
          compact: false
        ))

        expect(rendered.css('.card.compact')).to be_empty
        expect(rendered.css('.card')).to be_present
      end
    end
  end

  describe 'additional_classes parameter' do
    context 'when additional_classes is provided' do
      it 'appends additional classes to base class' do
        rendered = render_inline(described_class.new(
          item: item,
          form: form,
          field: :test_field,
          additional_classes: 'kind-card'
        ))

        root = rendered.css('div').first
        expect(root['class']).to include('card')
        expect(root['class']).to include('kind-card')
      end

      it 'works with multiple additional classes' do
        rendered = render_inline(described_class.new(
          item: item,
          form: form,
          field: :test_field,
          additional_classes: 'kind-card centered-text'
        ))

        root = rendered.css('div').first
        expect(root['class']).to include('card')
        expect(root['class']).to include('kind-card')
        expect(root['class']).to include('centered-text')
      end

      it 'combines with selected and compact states' do
        rendered = render_inline(described_class.new(
          item: item,
          form: form,
          field: :test_field,
          additional_classes: 'kind-card',
          selected: true,
          compact: true
        ))

        root = rendered.css('div').first
        expect(root['class']).to include('card')
        expect(root['class']).to include('kind-card')
        expect(root['class']).to include('selected')
        expect(root['class']).to include('compact')
      end
    end

    context 'when additional_classes is nil' do
      it 'uses only base class' do
        rendered = render_inline(described_class.new(
          item: item,
          form: form,
          field: :test_field,
          additional_classes: nil
        ))

        root = rendered.css('div').first
        expect(root['class']).to include('card')
        expect(root['class']).not_to include('kind-card')
      end
    end

    context 'with custom css_class and additional_classes' do
      it 'uses custom base class with additional classes' do
        rendered = render_inline(described_class.new(
          item: item,
          form: form,
          field: :test_field,
          css_class: 'premium-card',
          additional_classes: 'featured'
        ))

        root = rendered.css('div').first
        classes = root['class'].split
        expect(classes).to include('premium-card')
        expect(classes).to include('featured')
        expect(classes).not_to include('card')
      end
    end
  end

  describe 'combined features' do
    it 'works with all features together' do
      rendered = render_inline(described_class.new(
        item: item,
        form: form,
        field: :test_field,
        selected: true,
        compact: true,
        multiple: false,
        additional_classes: 'kind-card',
        show_visual_checkbox: false,
        css_class: 'custom-card'
      ))

      root = rendered.css('div').first
      expect(root['class']).to include('custom-card')
      expect(root['class']).to include('kind-card')
      expect(root['class']).to include('selected')
      expect(root['class']).to include('compact')

      expect(rendered.css('input[type="radio"]')).to be_present
      expect(rendered.css('.card-checkbox')).to be_empty
    end
  end
end
