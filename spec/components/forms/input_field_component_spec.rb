# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forms::InputFieldComponent, type: :component do
  let(:form) { mock_form_builder }
  let(:field) { :email }
  let(:component) { described_class.new(form: form, field: field) }

  it_behaves_like "a rendered component" do
    subject(:rendered_component) { render_inline(component) }
  end

  it_behaves_like "a form component" do
    subject(:rendered_component) { render_inline(component) }
  end

  describe "initialization" do
    it "accepts minimal required parameters" do
      expect(component).to be_instance_of(Forms::InputFieldComponent)
    end

    context "with custom parameters" do
      let(:component) do
        described_class.new(
          form: form,
          field: :password,
          type: :password_field,
          label: 'Custom Password',
          required: true,
          help_text: 'Enter a strong password'
        )
      end

      it "uses custom configuration" do
        expect(component.send(:type)).to eq(:password_field)
        expect(component.send(:label)).to eq('Custom Password')
        expect(component.send(:required)).to be true
        expect(component.send(:help_text)).to eq('Enter a strong password')
      end
    end
  end

  describe "label handling" do
    context "with custom label" do
      let(:component) { described_class.new(form: form, field: field, label: 'Email Address') }

      it "uses the provided label" do
        expect(component.send(:field_label)).to eq('Email Address')
      end
    end

    context "without custom label" do
      it "falls back to humanized field name" do
        allow(component).to receive(:t).and_return('Email')
        expect(component.send(:field_label)).to eq('Email')
      end
    end
  end

  describe "error handling" do
    context "without errors" do
      it "returns false for has_errors?" do
        expect(component.send(:has_errors?)).to be false
      end

      it "returns empty array for field_errors" do
        expect(component.send(:field_errors)).to eq([])
      end
    end

    context "with errors" do
      let(:form) { mock_form_with_errors }

      it "detects errors correctly" do
        email_component = described_class.new(form: form, field: :email)
        expect(email_component.send(:has_errors?)).to be true
      end

      it "returns error messages" do
        email_component = described_class.new(form: form, field: :email)
        expect(email_component.send(:field_errors)).to include("Email can't be blank")
      end
    end

    context "with nil form object" do
      let(:form) { mock_form_builder(nil) }

      it "handles gracefully" do
        expect(component.send(:has_errors?)).to be false
        expect(component.send(:field_errors)).to eq([])
      end
    end
  end

  describe "CSS class handling" do
    it "combines wrapper classes correctly" do
      component_with_classes = described_class.new(
        form: form,
        field: field,
        wrapper_classes: 'custom-wrapper'
      )

      classes = component_with_classes.send(:final_wrapper_classes)
      expect(classes).to include('form-field')
      expect(classes).to include('custom-wrapper')
    end

    it "combines field classes correctly" do
      component_with_classes = described_class.new(
        form: form,
        field: field,
        field_classes: 'custom-field'
      )

      classes = component_with_classes.send(:final_field_classes)
      expect(classes).to include('form-input')
      expect(classes).to include('custom-field')
    end

    it "adds error classes when field has errors" do
      form_with_errors = mock_form_with_errors
      component_with_errors = described_class.new(
        form: form_with_errors,
        field: :email
      )

      classes = component_with_errors.send(:final_field_classes)
      expect(classes).to include('form-input-error')
    end
  end

  describe "rendering behavior" do
    subject(:rendered) { render_inline(component) }

    it "renders the component structure" do
      expect(rendered.css('.form-field')).to be_present
    end

    it "renders label wrapper" do
      expect(rendered.css('.form-label-wrapper')).to be_present
    end

    it "renders form label" do
      expect(rendered.css('.form-label')).to be_present
    end

    context "with required field" do
      let(:component) { described_class.new(form: form, field: field, required: true) }

      it "shows required indicator" do
        expect(rendered.css('.form-label-required')).to be_present
        expect(rendered.to_html).to include('*')
      end
    end

    context "with help text" do
      let(:component) do
        described_class.new(
          form: form,
          field: field,
          help_text: 'We will never share your email'
        )
      end

      it "displays help text in correct element" do
        expect(rendered.css('.form-help-text').text).to include('We will never share your email')
      end
    end

    context "with form errors" do
      let(:form) { mock_form_with_errors }
      let(:field) { :email }

      it "displays error messages in error container" do
        expect(rendered.css('.form-errors')).to be_present
        expect(rendered.css('.form-error-message')).to be_present
        expect(rendered.to_html).to include("Email can't be blank")
      end

      it "adds error class to input field" do
        expect(rendered.css('.form-input-error')).to be_present
      end
    end
  end

  describe "input type handling" do
    let(:supported_types) { [ :text_field, :email_field, :password_field, :number_field, :url_field, :telephone_field ] }

    it "handles all supported input types without errors" do
      supported_types.each do |input_type|
        expect {
          render_inline(described_class.new(form: form, field: :email, type: input_type))
        }.not_to raise_error
      end
    end
  end

  describe "autocomplete functionality" do
    context "with autocomplete enabled" do
      let(:suggestions) { [ 'Option 1', 'Option 2', 'Option 3' ] }
      let(:component) do
        described_class.new(
          form: form,
          field: field,
          autocomplete: true,
          autocomplete_options: suggestions
        )
      end

      it "enables autocomplete when suggestions are provided" do
        expect(component.send(:use_autocomplete?)).to be true
      end

      it "includes tom-select controller in data attributes" do
        render_inline(component)
        data = component.send(:tom_select_data)
        expect(data[:controller]).to eq("tom-select")
      end

      it "includes suggestions in data attributes" do
        render_inline(component)
        data = component.send(:tom_select_data)
        expect(data[:tom_select_suggestions_value]).to eq(suggestions.to_json)
      end

      it "adds autocomplete class to field" do
        classes = component.send(:default_field_classes)
        expect(classes).to include('form-input-autocomplete')
      end

      context "with allow_create enabled" do
        let(:component) do
          described_class.new(
            form: form,
            field: field,
            autocomplete: true,
            autocomplete_options: suggestions,
            allow_create: true
          )
        end

        it "includes allow_create in data attributes" do
          render_inline(component)
          data = component.send(:tom_select_data)
          expect(data[:tom_select_allow_create_value]).to be true
        end
      end

      context "with custom placeholder" do
        let(:component) do
          described_class.new(
            form: form,
            field: field,
            autocomplete: true,
            autocomplete_options: suggestions,
            placeholder: "Type to search..."
          )
        end

        it "uses custom placeholder in tom-select data" do
          render_inline(component)
          data = component.send(:tom_select_data)
          expect(data[:tom_select_placeholder_value]).to eq("Type to search...")
        end
      end
    end

    context "without autocomplete" do
      it "disables autocomplete when no suggestions provided" do
        component = described_class.new(form: form, field: field, autocomplete: false)
        expect(component.send(:use_autocomplete?)).to be false
      end

      it "disables autocomplete when suggestions are empty" do
        component = described_class.new(
          form: form,
          field: field,
          autocomplete: true,
          autocomplete_options: []
        )
        expect(component.send(:use_autocomplete?)).to be false
      end
    end
  end

  describe "addon functionality" do
    let(:test_model) do
      Class.new do
        include ActiveModel::Model
        attr_accessor :amount, :percentage, :price

        def self.model_name
          ActiveModel::Name.new(self, nil, "TestModel")
        end
      end.new
    end
    let(:test_form) { mock_form_builder(test_model) }

    context "with prepend addon" do
      let(:component) do
        described_class.new(
          form: test_form,
          field: :amount,
          prepend: "XOF"
        )
      end

      it "detects prepend addon" do
        expect(component.send(:has_addon?)).to be true
      end

      subject(:rendered) { render_inline(component) }

      it "renders input group wrapper" do
        expect(rendered.css('.form-input-group')).to be_present
      end

      it "renders prepend addon" do
        expect(rendered.css('.form-input-addon--prepend')).to be_present
        expect(rendered.css('.form-input-addon--prepend').text).to eq('XOF')
      end
    end

    context "with append addon" do
      let(:component) do
        described_class.new(
          form: test_form,
          field: :percentage,
          append: "%"
        )
      end

      it "detects append addon" do
        expect(component.send(:has_addon?)).to be true
      end

      subject(:rendered) { render_inline(component) }

      it "renders input group wrapper" do
        expect(rendered.css('.form-input-group')).to be_present
      end

      it "renders append addon" do
        expect(rendered.css('.form-input-addon--append')).to be_present
        expect(rendered.css('.form-input-addon--append').text).to eq('%')
      end
    end

    context "with both prepend and append addons" do
      let(:component) do
        described_class.new(
          form: test_form,
          field: :price,
          prepend: "$",
          append: "USD"
        )
      end

      it "detects both addons" do
        expect(component.send(:has_addon?)).to be true
      end

      subject(:rendered) { render_inline(component) }

      it "renders both prepend and append addons" do
        expect(rendered.css('.form-input-addon--prepend')).to be_present
        expect(rendered.css('.form-input-addon--append')).to be_present
        expect(rendered.css('.form-input-addon--prepend').text).to eq('$')
        expect(rendered.css('.form-input-addon--append').text).to eq('USD')
      end
    end

    context "without addons" do
      let(:component) { described_class.new(form: form, field: field) }

      it "does not detect addons" do
        expect(component.send(:has_addon?)).to be false
      end

      subject(:rendered) { render_inline(component) }

      it "does not render input group wrapper" do
        expect(rendered.css('.form-input-group')).to be_empty
      end
    end
  end

  describe "field options handling" do
    context "with custom field options" do
      let(:component) do
        described_class.new(
          form: form,
          field: :amount,
          type: :number_field,
          step: "0.01",
          min: "0",
          max: "1000"
        )
      end

      it "includes custom options in final_field_options" do
        options = component.send(:final_field_options)
        expect(options[:step]).to eq("0.01")
        expect(options[:min]).to eq("0")
        expect(options[:max]).to eq("1000")
      end
    end

    context "with disabled field" do
      let(:component) do
        described_class.new(
          form: form,
          field: field,
          disabled: true
        )
      end

      subject(:rendered) { render_inline(component) }

      it "includes disabled attribute" do
        expect(rendered.to_html).to include('disabled')
      end
    end

    context "with placeholder" do
      let(:component) do
        described_class.new(
          form: form,
          field: field,
          placeholder: "Enter your email"
        )
      end

      it "includes placeholder in field options" do
        options = component.send(:final_field_options)
        expect(options[:placeholder]).to eq("Enter your email")
      end
    end
  end

  describe "placeholder handling with autocomplete" do
    context "when autocomplete is enabled" do
      let(:component) do
        described_class.new(
          form: form,
          field: field,
          autocomplete: true,
          autocomplete_options: [ 'Option 1' ],
          placeholder: "Type to search..."
        )
      end

      it "removes placeholder from field options" do
        options = component.send(:final_field_options)
        expect(options[:placeholder]).to be_nil
      end

      it "includes placeholder in tom-select data instead" do
        data = component.send(:tom_select_data)
        expect(data[:tom_select_placeholder_value]).to eq("Type to search...")
      end
    end
  end

  describe "autocomplete_options_for_select" do
    context "with simple array" do
      let(:component) do
        described_class.new(
          form: form,
          field: field,
          autocomplete: true,
          autocomplete_options: [ 'Apple', 'Banana', 'Cherry' ]
        )
      end

      it "converts to [label, value] format" do
        result = component.send(:autocomplete_options_for_select)
        expect(result).to eq([ [ 'Apple', 'Apple' ], [ 'Banana', 'Banana' ], [ 'Cherry', 'Cherry' ] ])
      end
    end

    context "with array of arrays" do
      let(:component) do
        described_class.new(
          form: form,
          field: field,
          autocomplete: true,
          autocomplete_options: [ [ 'Apple Label', 'apple' ], [ 'Banana Label', 'banana' ] ]
        )
      end

      it "keeps the [label, value] format" do
        result = component.send(:autocomplete_options_for_select)
        expect(result).to eq([ [ 'Apple Label', 'apple' ], [ 'Banana Label', 'banana' ] ])
      end
    end

    context "with array of hashes" do
      let(:component) do
        described_class.new(
          form: form,
          field: field,
          autocomplete: true,
          autocomplete_options: [
            { label: 'Apple', value: 'apple' },
            { text: 'Banana', id: 'banana' }
          ]
        )
      end

      it "converts to [label, value] format" do
        result = component.send(:autocomplete_options_for_select)
        expect(result).to eq([ [ 'Apple', 'apple' ], [ 'Banana', 'banana' ] ])
      end
    end

    context "without autocomplete" do
      let(:component) { described_class.new(form: form, field: field) }

      it "returns empty array" do
        result = component.send(:autocomplete_options_for_select)
        expect(result).to eq([])
      end
    end
  end

  describe "integration with number fields and addons" do
    # Create a test model with amount field
    let(:test_model) do
      Class.new do
        include ActiveModel::Model
        attr_accessor :amount

        def self.model_name
          ActiveModel::Name.new(self, nil, "TestModel")
        end
      end.new
    end
    let(:test_form) { mock_form_builder(test_model) }

    let(:component) do
      described_class.new(
        form: test_form,
        field: :amount,
        type: :number_field,
        prepend: "XOF",
        step: "0.01",
        min: "0"
      )
    end

    subject(:rendered) { render_inline(component) }

    it "renders all features together correctly" do
      expect(rendered.css('.form-input-group')).to be_present
      expect(rendered.css('.form-input-addon--prepend').text).to eq('XOF')
      expect(rendered.to_html).to include('step="0.01"')
      expect(rendered.to_html).to include('min="0"')
    end
  end
end
