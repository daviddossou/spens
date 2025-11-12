# frozen_string_literal: true

require "rails_helper"

RSpec.describe Forms::RadioButtonFieldComponent, type: :component do
  let(:object) { double("object", errors: errors) }
  let(:errors) { double("errors", key?: false, full_messages_for: []) }
  let(:form) { double("form", object: object, radio_button: radio_button_html, label: label_html) }
  let(:radio_button_html) { '<input type="radio" name="test" value="option1" id="test_option1" />'.html_safe }
  let(:label_html) { '<label for="test_option1">Option 1</label>'.html_safe }

  describe "rendering" do
    it "renders a radio button field" do
      rendered = render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1"
      ))

      expect(rendered.to_html).to include('class="radio-field"')
      expect(rendered.to_html).to include('radio-input-wrapper')
    end

    it "renders with custom label" do
      rendered = render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        label: "Custom Label"
      ))

      expect(form).to have_received(:label).with("test_option1", "Custom Label", class: nil)
    end

    it "renders with help text" do
      rendered = render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        help_text: "Choose wisely"
      ))

      expect(rendered.css('.help-text').text).to eq("Choose wisely")
    end
  end

  describe "checked state" do
    it "passes checked: true to radio button" do
      expect(form).to receive(:radio_button).with(
        :test,
        "option1",
        hash_including(checked: true)
      ).and_return(radio_button_html)

      render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        checked: true
      ))
    end

    it "passes checked: false to radio button" do
      expect(form).to receive(:radio_button).with(
        :test,
        "option1",
        hash_including(checked: false)
      ).and_return(radio_button_html)

      render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        checked: false
      ))
    end

    it "doesn't pass checked when nil" do
      expect(form).to receive(:radio_button).with(
        :test,
        "option1",
        hash_not_including(:checked)
      ).and_return(radio_button_html)

      render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        checked: nil
      ))
    end
  end

  describe "custom classes" do
    it "applies custom wrapper classes" do
      rendered = render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        wrapper_classes: "custom-wrapper"
      ))

      wrapper = rendered.css('div').first
      expect(wrapper['class']).to include('radio-field')
      expect(wrapper['class']).to include('custom-wrapper')
    end

    it "applies custom label classes" do
      rendered = render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        label: "Test Label",
        label_classes: "font-bold text-lg"
      ))

      expect(form).to have_received(:label).with(
        "test_option1",
        "Test Label",
        class: "font-bold text-lg"
      )
    end

    it "applies custom radio classes" do
      expect(form).to receive(:radio_button).with(
        :test,
        "option1",
        hash_including(class: "custom-radio accent-blue")
      ).and_return(radio_button_html)

      render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        radio_classes: "custom-radio accent-blue"
      ))
    end

    it "merges radio classes with field_options class" do
      expect(form).to receive(:radio_button).with(
        :test,
        "option1",
        hash_including(class: "custom-radio extra-class")
      ).and_return(radio_button_html)

      render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        radio_classes: "custom-radio",
        class: "extra-class"
      ))
    end
  end

  describe "wrapper data attributes" do
    it "applies custom data attributes to wrapper" do
      rendered = render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        wrapper_data: {
          controller: "radio",
          action: "change->radio#toggle"
        }
      ))

      wrapper = rendered.css('div').first
      expect(wrapper['data-controller']).to eq('radio')
      expect(wrapper['data-action']).to eq('change->radio#toggle')
    end
  end

  describe "hide_label option" do
    it "hides label when hide_label is true" do
      rendered = render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        label: "Hidden Label",
        hide_label: true
      ))

      expect(rendered.css('label')).to be_empty
    end

    it "hides help text when hide_label is true" do
      rendered = render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        help_text: "This should be hidden",
        hide_label: true
      ))

      expect(rendered.css('.help-text')).to be_empty
    end

    it "hides error messages when hide_label is true" do
      allow(errors).to receive(:key?).with(:test).and_return(true)
      allow(errors).to receive(:full_messages_for).with(:test).and_return(["Test can't be blank"])

      rendered = render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        hide_label: true
      ))

      expect(rendered.css('.error-messages')).to be_empty
    end
  end

  describe "error handling" do
    context "when field has errors" do
      before do
        allow(errors).to receive(:key?).with(:test).and_return(true)
        allow(errors).to receive(:full_messages_for).with(:test).and_return([
          "Test can't be blank",
          "Test is invalid"
        ])
      end

      it "adds has-errors class to wrapper" do
        rendered = render_inline(described_class.new(
          form: form,
          field: :test,
          value: "option1"
        ))

        wrapper = rendered.css('div').first
        expect(wrapper['class']).to include('has-errors')
      end

      it "displays error messages" do
        rendered = render_inline(described_class.new(
          form: form,
          field: :test,
          value: "option1"
        ))

        error_texts = rendered.css('.error-text').map(&:text)
        expect(error_texts).to include("Test can't be blank")
        expect(error_texts).to include("Test is invalid")
      end
    end

    context "when field has no errors" do
      it "doesn't add has-errors class" do
        rendered = render_inline(described_class.new(
          form: form,
          field: :test,
          value: "option1"
        ))

        wrapper = rendered.css('div').first
        expect(wrapper['class']).not_to include('has-errors')
      end

      it "doesn't display error messages" do
        rendered = render_inline(described_class.new(
          form: form,
          field: :test,
          value: "option1"
        ))

        expect(rendered.css('.error-messages')).to be_empty
      end
    end
  end

  describe "content block" do
    it "renders content block as label when provided" do
      rendered = render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1"
      )) do
        "Custom content with <strong>HTML</strong>".html_safe
      end

      label = rendered.css('label').first
      expect(label.to_html).to include('Custom content with <strong>HTML</strong>')
    end

    it "prefers content block over label parameter" do
      rendered = render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        label: "This should be ignored"
      )) do
        "Content block wins"
      end

      label = rendered.css('label').first
      expect(label.text).to eq('Content block wins')
      expect(form).not_to have_received(:label)
    end
  end

  describe "field options passthrough" do
    it "passes additional field options to radio_button" do
      expect(form).to receive(:radio_button).with(
        :test,
        "option1",
        hash_including(
          disabled: true,
          data: { action: "click->test#handle" }
        )
      ).and_return(radio_button_html)

      render_inline(described_class.new(
        form: form,
        field: :test,
        value: "option1",
        disabled: true,
        data: { action: "click->test#handle" }
      ))
    end
  end
end
