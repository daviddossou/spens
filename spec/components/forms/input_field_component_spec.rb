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
      expect(classes).to include('space-y-1')
      expect(classes).to include('custom-wrapper')
    end

    it "combines field classes correctly" do
      component_with_classes = described_class.new(
        form: form,
        field: field,
        field_classes: 'custom-field'
      )

      classes = component_with_classes.send(:final_field_classes)
      expect(classes).to include('appearance-none block w-full px-3 py-2 border border-slate-gray rounded-md placeholder-gray-400 focus:outline-none focus:ring-secondary focus:border-steel-blue sm:text-sm')
      expect(classes).to include('custom-field')
    end
  end

  describe "rendering behavior" do
    subject(:rendered) { render_inline(component) }

    it "renders the component structure" do
      expect(rendered.css('div')).to be_present
    end

    context "with required field" do
      let(:component) { described_class.new(form: form, field: field, required: true) }

      it "shows required indicator" do
        expect(rendered.to_html).to include('*')
        expect(rendered.to_html).to include('text-danger')
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

      it "displays help text" do
        expect(rendered.to_html).to include('We will never share your email')
      end
    end

    context "with form errors" do
      let(:form) { mock_form_with_errors }
      let(:field) { :email }

      it "displays error messages" do
        expect(rendered.to_html).to include("Email can't be blank")
        expect(rendered.to_html).to include('text-danger')
      end
    end
  end

  describe "input type handling" do
    let(:supported_types) { [:text_field, :email_field, :password_field, :number_field, :url_field, :tel_field] }

    it "handles all supported input types without errors" do
      supported_types.each do |input_type|
        expect {
          render_inline(described_class.new(form: form, field: :test, type: input_type))
        }.not_to raise_error
      end
    end
  end
end
