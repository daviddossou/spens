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
      expect(classes).to include('checkbox-field')
      expect(classes).to include('custom-wrapper')
    end

    it "combines checkbox classes correctly" do
      component_with_classes = described_class.new(
        form: form,
        field: field,
        checkbox_classes: 'custom-checkbox'
      )

      classes = component_with_classes.send(:checkbox_classes)
      expect(classes).to include('custom-checkbox')
    end

    it "combines label classes correctly" do
      component_with_classes = described_class.new(
        form: form,
        field: field,
        label_classes: 'custom-label'
      )

      classes = component_with_classes.send(:label_classes)
      expect(classes).to include('custom-label')
    end

    it "adds has-errors class when form has errors" do
      component_with_errors = described_class.new(
        form: mock_form_with_errors,
        field: :email
      )

      classes = component_with_errors.send(:final_wrapper_classes)
      expect(classes).to include('checkbox-field')
      expect(classes).to include('has-errors')
    end
  end

  describe "rendering behavior" do
    subject(:rendered) { render_inline(component) }

    it "renders the component structure with correct CSS classes" do
      expect(rendered.css('.checkbox-field')).to be_present
      expect(rendered.css('.checkbox-input-wrapper')).to be_present
    end

    it "renders checkbox and label in the input wrapper" do
      checkbox_wrapper = rendered.css('.checkbox-input-wrapper').first
      expect(checkbox_wrapper.css('input[type="checkbox"]')).to be_present
      expect(checkbox_wrapper.css('label')).to be_present
    end

    context "with help text" do
      let(:component) do
        described_class.new(
          form: form,
          field: field,
          help_text: 'This will keep you logged in'
        )
      end

      it "displays help text with correct class" do
        expect(rendered.to_html).to include('This will keep you logged in')
        expect(rendered.css('.help-text')).to be_present
      end

      it "renders help text outside the input wrapper" do
        expect(rendered.css('.checkbox-field .help-text')).to be_present
        expect(rendered.css('.checkbox-input-wrapper .help-text')).to be_empty
      end
    end

    context "with form errors" do
      let(:form) { mock_form_with_errors }
      let(:field) { :email }

      it "displays error messages with correct class" do
        expect(rendered.to_html).to include("Email can't be blank")
        expect(rendered.css('.error-text')).to be_present
      end

      it "adds has-errors class to wrapper" do
        expect(rendered.css('.checkbox-field.has-errors')).to be_present
      end

      it "renders error messages outside the input wrapper" do
        expect(rendered.css('.checkbox-field .error-messages')).to be_present
        expect(rendered.css('.checkbox-input-wrapper .error-messages')).to be_empty
      end
    end
  end

  describe "multiple checkbox behavior" do
    context "when multiple: true" do
      let(:component) do
        described_class.new(
          form: form,
            field: :financial_goals,
            multiple: true,
            value: 'save_for_emergency',
            checked: true,
            label: 'Emergency Fund'
        )
      end

      it "renders a checkbox with the provided value" do
        html = render_inline(component).to_html
        expect(html).to include('value="save_for_emergency"')
      end

      it "marks the checkbox as checked when checked: true" do
        node = render_inline(component).css('input[type="checkbox"]').first
        expect(node[:checked]).to be_present
      end

      it "renders array field name for multiple checkboxes" do
        html = render_inline(component).to_html
        # Rails handles multiple checkboxes by using array notation in the name
        expect(html).to include('name="user[financial_goals][]"')
      end
    end

    context "when multiple: false (default)" do
      it "does not add multiple attribute" do
        node = render_inline(component).css('input[type="checkbox"]').first
        expect(node[:multiple]).to be_nil
      end
    end
  end

  describe "hide_label option" do
    it "suppresses label when hide_label: true" do
      hidden_label_component = described_class.new(form: form, field: field, label: 'Should Not Show', hide_label: true)
      html = render_inline(hidden_label_component).to_html
      expect(html).not_to include('Should Not Show')
    end

    it "suppresses error messages when hide_label: true" do
      error_form = mock_form_with_errors
      hidden_error_component = described_class.new(form: error_form, field: :email, hide_label: true)
      html = render_inline(hidden_error_component).to_html
      expect(html).not_to include("Email can't be blank")
    end
  end

  describe "wrapper data attributes" do
    it "renders provided wrapper data attributes" do
      data_component = described_class.new(form: form, field: field, wrapper_data: { controller: 'tracking', action: 'click->tracking#record' })
      node = render_inline(data_component).css('div').first
      expect(node["data-controller"]).to eq('tracking')
      expect(node["data-action"]).to eq('click->tracking#record')
    end
  end

  describe "final_field_options merging" do
    it "merges custom class into checkbox classes" do
      custom = described_class.new(form: form, field: field, checkbox_classes: 'extra-class')
      node = render_inline(custom).css('input[type="checkbox"]').first
      expect(node[:class]).to include('extra-class')
    end

    it "handles empty default checkbox classes" do
      custom = described_class.new(form: form, field: field)
      classes = custom.send(:checkbox_classes)

      expect(classes.to_s.strip).to be_empty
    end
  end
end
