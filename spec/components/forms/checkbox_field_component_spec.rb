# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forms::CheckboxFieldComponent, type: :component do
  let(:form) { mock_form_builder }
  let(:field) { :remember_me }
  let(:component) { described_class.new(form: form, field: field) }

  it_behaves_like "a rendered component" do
    subject(:rendered_component) { render_inline(component) }
  end

  it_behaves_like "a form component" do
    subject(:rendered_component) { render_inline(component) }
  end

  describe "initialization" do
    it "accepts minimal required parameters" do
      expect(component).to be_instance_of(Forms::CheckboxFieldComponent)
    end

    context "with custom parameters" do
      let(:component) do
        described_class.new(
          form: form,
          field: :terms_accepted,
          label: 'I accept the terms',
          help_text: 'Please read our terms carefully'
        )
      end

      it "uses custom configuration" do
        expect(component.send(:label)).to eq('I accept the terms')
        expect(component.send(:help_text)).to eq('Please read our terms carefully')
      end
    end
  end

  describe "label handling" do
    context "with custom label" do
      let(:component) { described_class.new(form: form, field: field, label: 'Remember my login') }

      it "uses the provided label" do
        expect(component.send(:field_label)).to eq('Remember my login')
      end
    end

    context "without custom label" do
      it "falls back to humanized field name" do
        allow(component).to receive(:t).and_return('Remember me')
        expect(component.send(:field_label)).to eq('Remember me')
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

      it "detects errors correctly when field has errors" do
        email_component = described_class.new(form: form, field: :email)
        expect(email_component.send(:has_errors?)).to be true
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
      expect(classes).to include('flex items-center')
      expect(classes).to include('custom-wrapper')
    end

    it "combines checkbox classes correctly" do
      component_with_classes = described_class.new(
        form: form,
        field: field,
        checkbox_classes: 'custom-checkbox'
      )

      classes = component_with_classes.send(:final_checkbox_classes)
      expect(classes).to include('h-4 w-4 text-primary focus:ring-secondary border-gray-300 rounded')
      expect(classes).to include('custom-checkbox')
    end

    it "combines label classes correctly" do
      component_with_classes = described_class.new(
        form: form,
        field: field,
        label_classes: 'custom-label'
      )

      classes = component_with_classes.send(:final_label_classes)
      expect(classes).to include('ml-2 block text-sm text-gray-900')
      expect(classes).to include('custom-label')
    end
  end

  describe "rendering behavior" do
    subject(:rendered) { render_inline(component) }

    it "renders the component structure" do
      expect(rendered.css('div')).to be_present
    end

    context "with help text" do
      let(:component) do
        described_class.new(
          form: form,
          field: field,
          help_text: 'This will keep you logged in'
        )
      end

      it "displays help text" do
        expect(rendered.to_html).to include('This will keep you logged in')
      end
    end

    context "with form errors" do
      let(:form) { mock_form_with_errors }
      let(:field) { :email }

      it "displays error messages" do
        expect(rendered.to_html).to include("Email can't be blank")
      end
    end
  end
end
