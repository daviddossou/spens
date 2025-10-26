# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forms::SelectFieldComponent, type: :component do
  let(:form) { mock_form_builder }
  let(:field) { :country }
  let(:options) { { 'US' => 'United States', 'CA' => 'Canada', 'MX' => 'Mexico' } }
  let(:component) { described_class.new(form: form, field: field, options: options) }

  it_behaves_like "a rendered component" do
    subject(:rendered_component) { render_inline(component) }
  end

  it_behaves_like "a form component" do
    subject(:rendered_component) { render_inline(component) }
  end

  describe "initialization" do
    it "accepts minimal required parameters" do
      expect(component).to be_instance_of(Forms::SelectFieldComponent)
    end

    context "with custom parameters" do
      let(:component) do
        described_class.new(
          form: form,
          field: :currency,
          options: options,
          label: 'Select Currency',
          required: true,
          help_text: 'Choose your preferred currency',
          include_blank: 'Please select...'
        )
      end

      it "uses custom configuration" do
        expect(component.send(:label)).to eq('Select Currency')
        expect(component.send(:required)).to be true
        expect(component.send(:help_text)).to eq('Choose your preferred currency')
        expect(component.send(:include_blank)).to eq('Please select...')
      end
    end
  end

  describe "label handling" do
    context "with custom label" do
      let(:component) { described_class.new(form: form, field: field, options: options, label: 'Select Country') }

      it "uses the provided label" do
        expect(component.send(:field_label)).to eq('Select Country')
      end
    end

    context "without custom label" do
      it "falls back to humanized field name" do
        expect(component.send(:field_label)).to eq('Country')
      end
    end
  end

  describe "options handling" do
    context "with hash options" do
      let(:options) { { 'US' => 'United States', 'CA' => 'Canada' } }

      it "converts hash to select options format" do
        result = component.send(:options_for_select)
        expect(result).to contain_exactly(
          [ 'United States', 'US' ],
          [ 'Canada', 'CA' ]
        )
      end
    end

    context "with array of arrays" do
      let(:options) { [ [ 'United States', 'US' ], [ 'Canada', 'CA' ] ] }

      it "uses array as-is" do
        result = component.send(:options_for_select)
        expect(result).to eq(options)
      end
    end

    context "with simple array" do
      let(:options) { [ 'Small', 'Medium', 'Large' ] }

      it "converts to label-value pairs" do
        result = component.send(:options_for_select)
        expect(result).to contain_exactly(
          [ 'Small', 'Small' ],
          [ 'Medium', 'Medium' ],
          [ 'Large', 'Large' ]
        )
      end
    end
  end

  describe "error handling" do
    context "without errors" do
      it "returns false for has_errors?" do
        expect(component.send(:has_errors?)).to be false
      end

      it "returns empty array for error_messages" do
        expect(component.send(:error_messages)).to eq([])
      end
    end

    context "with errors" do
      let(:form) { mock_form_with_errors }
      let(:component) { described_class.new(form: form, field: :email, options: options) }

      it "detects errors correctly" do
        expect(component.send(:has_errors?)).to be true
      end

      it "returns error messages" do
        expect(component.send(:error_messages)).to include(/Email/)
      end
    end
  end

  describe "CSS classes" do
    context "without errors" do
      it "applies default field classes" do
        expect(component.send(:default_field_classes)).to include('form-select')
        expect(component.send(:default_field_classes)).not_to include('form-select-error')
      end
    end

    context "with errors" do
      let(:form) { mock_form_with_errors }
      let(:component) { described_class.new(form: form, field: :email, options: options) }

      it "applies error classes" do
        expect(component.send(:default_field_classes)).to include('form-select-error')
      end
    end

    context "with custom classes" do
      let(:component) do
        described_class.new(
          form: form,
          field: field,
          options: options,
          wrapper_classes: 'custom-wrapper',
          label_classes: 'custom-label',
          field_classes: 'custom-field'
        )
      end

      it "merges custom wrapper classes" do
        expect(component.send(:final_wrapper_classes)).to include('form-field')
        expect(component.send(:final_wrapper_classes)).to include('custom-wrapper')
      end

      it "merges custom label classes" do
        expect(component.send(:final_label_classes)).to include('form-label')
        expect(component.send(:final_label_classes)).to include('custom-label')
      end

      it "merges custom field classes" do
        expect(component.send(:final_field_classes)).to include('form-select')
        expect(component.send(:final_field_classes)).to include('custom-field')
      end
    end
  end

  describe "rendering" do
    let(:rendered) { render_inline(component) }

    it "renders a select element" do
      expect(rendered.css('select').first).to be_present
    end

    it "renders a label" do
      expect(rendered.css('label').first).to be_present
      expect(rendered.css('label').text).to include('Country')
    end

    it "renders all options" do
      expect(rendered.css('option').count).to eq(3)
    end

    context "with help text" do
      let(:component) do
        described_class.new(
          form: form,
          field: field,
          options: options,
          help_text: 'Select your country'
        )
      end

      it "renders help text" do
        expect(rendered.css('.form-help-text').first).to be_present
        expect(rendered.css('.form-help-text').text).to include('Select your country')
      end
    end

    context "with blank option" do
      let(:component) do
        described_class.new(
          form: form,
          field: field,
          options: options,
          include_blank: 'Choose one...'
        )
      end

      it "renders blank option" do
        expect(rendered.css('option').count).to eq(4) # 3 regular + 1 blank
      end
    end

    context "with errors" do
      let(:form) { mock_form_with_errors }
      let(:component) { described_class.new(form: form, field: :email, options: options) }

      it "renders error messages" do
        expect(rendered.css('.form-errors').first).to be_present
        expect(rendered.css('.form-error-message').count).to be > 0
      end

      it "applies error classes to select" do
        expect(rendered.css('select').first['class']).to include('form-select-error')
      end
    end
  end

  describe "field options" do
    let(:component) do
      described_class.new(
        form: form,
        field: field,
        options: options,
        disabled: true,
        data: { controller: 'select' }
      )
    end

    it "passes additional options to the select tag" do
      rendered = render_inline(component)
      select_element = rendered.css('select').first

      expect(select_element['disabled']).to be_present
      expect(select_element['data-controller']).to eq('select')
    end
  end

  describe "searchable select" do
    let(:component) do
      described_class.new(
        form: form,
        field: field,
        options: options,
        searchable: true
      )
    end

    it "adds searchable-select class" do
      expect(component.send(:default_field_classes)).to include('searchable-select')
    end

    it "adds data-controller attribute" do
      expect(component.send(:final_field_options)[:data][:controller]).to include('searchable-select')
    end

    context "when rendered" do
      let(:rendered) { render_inline(component) }

      it "includes searchable classes on select element" do
        expect(rendered.css('select.searchable-select').first).to be_present
      end

      it "includes stimulus controller in data attribute" do
        select_element = rendered.css('select').first
        expect(select_element['data-controller']).to include('searchable-select')
      end
    end
  end

  describe "priority options" do
    let(:priority_options) { { 'US' => 'United States', 'CA' => 'Canada' } }
    let(:component) do
      described_class.new(
        form: form,
        field: field,
        options: options,
        priority_options: priority_options
      )
    end

    it "detects priority options" do
      expect(component.send(:has_priority_options?)).to be true
    end

    it "converts priority options to correct format" do
      result = component.send(:priority_options_for_select)
      expect(result).to contain_exactly(
        [ 'United States', 'US' ],
        [ 'Canada', 'CA' ]
      )
    end

    it "excludes priority options from regular options" do
      regular = component.send(:regular_options_for_select)
      expect(regular).to contain_exactly([ 'Mexico', 'MX' ])
    end

    context "without priority options" do
      let(:component) do
        described_class.new(
          form: form,
          field: field,
          options: options
        )
      end

      it "returns false for has_priority_options?" do
        expect(component.send(:has_priority_options?)).to be false
      end

      it "returns all options as regular options" do
        regular = component.send(:regular_options_for_select)
        expect(regular.count).to eq(3)
      end
    end
  end

  describe "convert_options_format" do
    it "converts hash options" do
      result = component.send(:convert_options_format, { 'US' => 'United States' })
      expect(result).to eq([[ 'United States', 'US' ]])
    end

    it "keeps array of arrays as-is" do
      input = [[ 'United States', 'US' ]]
      result = component.send(:convert_options_format, input)
      expect(result).to eq(input)
    end

    it "converts simple array" do
      result = component.send(:convert_options_format, [ 'Small', 'Large' ])
      expect(result).to contain_exactly(
        [ 'Small', 'Small' ],
        [ 'Large', 'Large' ]
      )
    end
  end
end
