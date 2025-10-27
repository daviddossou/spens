# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ui::ButtonComponent, type: :component do
  let(:component) { described_class.new(text: "Click me") }

  it_behaves_like "a rendered component" do
    subject(:rendered_component) { render_inline(component) }
  end

  describe "initialization" do
    it "accepts minimal required parameters" do
      simple_component = described_class.new(text: "Test")
      expect(simple_component).to be_instance_of(Ui::ButtonComponent)
    end

    context "with all parameters" do
      let(:component) do
        described_class.new(
          text: "Submit",
          type: :submit,
          variant: :primary,
          size: :lg,
          disabled: true,
          loading: true,
          full_width: true,
          classes: 'custom-class'
        )
      end

      it "uses custom configuration" do
        expect(component.send(:text)).to eq("Submit")
        expect(component.send(:type)).to eq(:submit)
        expect(component.send(:variant)).to eq(:primary)
        expect(component.send(:size)).to eq(:lg)
        expect(component.send(:disabled)).to be true
        expect(component.send(:loading)).to be true
        expect(component.send(:full_width)).to be true
        expect(component.send(:classes)).to eq('custom-class')
      end
    end
  end

  describe "variant handling" do
    let(:variants) { [ :primary, :secondary, :danger, :success, :warning, :outline ] }

    it "handles all supported variants" do
      variants.each do |variant|
        variant_component = described_class.new(text: "Test", variant: variant)
        classes = variant_component.send(:button_classes)
        expect(classes).to include("btn-#{variant}")
      end
    end

    context "with primary variant" do
      let(:component) { described_class.new(text: "Test", variant: :primary) }

      it "applies primary CSS classes" do
        classes = component.send(:button_classes)
        expect(classes).to include('btn')
        expect(classes).to include('btn-primary')
      end
    end

    context "with secondary variant" do
      let(:component) { described_class.new(text: "Test", variant: :secondary) }

      it "applies secondary CSS classes" do
        classes = component.send(:button_classes)
        expect(classes).to include('btn')
        expect(classes).to include('btn-secondary')
      end
    end
  end

  describe "size handling" do
    let(:sizes) { [ :xs, :sm, :md, :lg, :xl ] }

    it "handles all supported sizes" do
      sizes.each do |size|
        size_component = described_class.new(text: "Test", size: size)
        classes = size_component.send(:button_classes)
        expect(classes).to include("btn-#{size}")
      end
    end

    context "with medium size" do
      let(:component) { described_class.new(text: "Test", size: :md) }

      it "applies medium size CSS classes" do
        classes = component.send(:button_classes)
        expect(classes).to include('btn')
        expect(classes).to include('btn-md')
      end
    end
  end

  describe "state handling" do
    context "when disabled" do
      let(:component) { described_class.new(text: "Test", disabled: true) }

      it "applies disabled CSS class" do
        classes = component.send(:button_classes)
        expect(classes).to include('disabled')
      end
    end

    context "when loading" do
      let(:component) { described_class.new(text: "Test", loading: true) }

      it "applies loading CSS class" do
        classes = component.send(:button_classes)
        expect(classes).to include('loading')
      end

      it "renders loading spinner with CSS class" do
        spinner = component.send(:loading_spinner)
        expect(spinner).to include('btn-spinner')
      end
    end
  end

  describe "button type detection" do
    context "as submit button" do
      let(:component) { described_class.new(text: "Submit", type: :submit) }

      it "detects submit type" do
        expect(component.send(:is_submit?)).to be true
        expect(component.send(:button_type)).to eq(:submit)
      end
    end

    context "as link button" do
      let(:component) { described_class.new(text: "Link", url: "/path") }

      it "detects link type" do
        expect(component.send(:is_link?)).to be true
      end
    end

    context "with form builder" do
      let(:form) { mock_form_builder }
      let(:component) { described_class.new(text: "Submit", form: form) }

      it "detects form builder" do
        expect(component.send(:is_form_builder?)).to be true
      end
    end

    context "with form ID string" do
      let(:component) { described_class.new(text: "Submit", type: :submit, form: "external-form") }

      it "does not detect as form builder" do
        expect(component.send(:is_form_builder?)).to be false
      end
    end
  end

  describe "rendering behavior" do
    subject(:rendered) { render_inline(component) }

    it "renders button element by default" do
      expect(rendered.css('button')).to be_present
    end

    context "with custom text" do
      let(:component) { described_class.new(text: "Custom Button Text") }

      it "displays the text" do
        expect(rendered.to_html).to include("Custom Button Text")
      end
    end

    context "when disabled" do
      let(:component) { described_class.new(text: "Test", disabled: true) }

      it "has disabled attribute" do
        expect(rendered.to_html).to include('disabled')
      end
    end

    context "when loading" do
      let(:component) { described_class.new(text: "Test", loading: true) }

      it "shows loading spinner with CSS class" do
        expect(rendered.to_html).to include('btn-spinner')
      end
    end

    context "with full width" do
      let(:component) { described_class.new(text: "Test", full_width: true) }

      it "applies full width CSS class" do
        classes = component.send(:button_classes)
        expect(classes).to include('btn-full-width')
      end
    end
  end

  describe "CSS class combination" do
    let(:component) do
      described_class.new(
        text: "Test",
        variant: :primary,
        size: :md,
        classes: 'custom-class'
      )
    end

    it "combines all CSS classes correctly" do
      classes = component.send(:button_classes)
      expect(classes).to include('btn')          # base
      expect(classes).to include('btn-primary')  # variant
      expect(classes).to include('btn-md')       # size
      expect(classes).to include('custom-class') # custom
    end
  end

  describe "#full_width_class" do
    it "returns class when full_width is true" do
      component = described_class.new(text: "Test", full_width: true)
      expect(component.send(:full_width_class)).to eq("btn-full-width")
    end

    it "returns nil when full_width is false" do
      component = described_class.new(text: "Test", full_width: false)
      expect(component.send(:full_width_class)).to be_nil
    end
  end

  describe "#state_classes" do
    it "returns nil when no states are active" do
      component = described_class.new(text: "Test")
      expect(component.send(:state_classes)).to be_nil
    end

    it "returns disabled when disabled" do
      component = described_class.new(text: "Test", disabled: true)
      expect(component.send(:state_classes)).to eq("disabled")
    end

    it "returns loading when loading" do
      component = described_class.new(text: "Test", loading: true)
      expect(component.send(:state_classes)).to eq("loading")
    end

    it "returns both states when both are active" do
      component = described_class.new(text: "Test", disabled: true, loading: true)
      expect(component.send(:state_classes)).to eq("disabled loading")
    end
  end

  describe "#final_data" do
    it "returns data as-is when not a link" do
      component = described_class.new(text: "Test", data: { action: "click->test#method" })
      expect(component.send(:final_data)).to eq({ action: "click->test#method" })
    end

    it "adds turbo-method when is link with non-get method" do
      component = described_class.new(text: "Delete", url: "/path", method: :delete)
      expect(component.send(:final_data)).to eq({ "turbo-method" => :delete })
    end

    it "does not add turbo-method for get requests" do
      component = described_class.new(text: "View", url: "/path", method: :get)
      expect(component.send(:final_data)).to eq({})
    end

    it "preserves existing data when adding turbo-method" do
      component = described_class.new(
        text: "Delete",
        url: "/path",
        method: :post,
        data: { turbo_confirm: "Are you sure?" }
      )
      expect(component.send(:final_data)).to eq({
        turbo_confirm: "Are you sure?",
        "turbo-method" => :post
      })
    end
  end

  describe "#final_options" do
    it "includes class attribute" do
      component = described_class.new(text: "Test", variant: :primary)
      options = component.send(:final_options)
      expect(options[:class]).to include("btn")
      expect(options[:class]).to include("btn-primary")
    end

    it "includes data attribute" do
      component = described_class.new(text: "Test", data: { action: "click->test#method" })
      options = component.send(:final_options)
      expect(options[:data]).to eq({ action: "click->test#method" })
    end

    it "includes type attribute for buttons" do
      component = described_class.new(text: "Submit", type: :submit)
      options = component.send(:final_options)
      expect(options[:type]).to eq(:submit)
    end

    it "does not include type attribute for links" do
      component = described_class.new(text: "Link", url: "/path")
      options = component.send(:final_options)
      expect(options).not_to have_key(:type)
    end

    it "includes disabled attribute when disabled" do
      component = described_class.new(text: "Test", disabled: true)
      options = component.send(:final_options)
      expect(options[:disabled]).to be true
    end

    it "does not include disabled attribute when not disabled" do
      component = described_class.new(text: "Test", disabled: false)
      options = component.send(:final_options)
      expect(options[:disabled]).to be_nil
    end

    it "preserves additional options" do
      component = described_class.new(text: "Test", title: "Tooltip", id: "my-button")
      options = component.send(:final_options)
      expect(options[:title]).to eq("Tooltip")
      expect(options[:id]).to eq("my-button")
    end

    it "includes form attribute when form is present" do
      component = described_class.new(text: "Submit", type: :submit, form: "external-form")
      options = component.send(:final_options)
      expect(options[:form]).to eq("external-form")
    end

    it "does not include form attribute when form is nil" do
      component = described_class.new(text: "Submit", type: :submit)
      options = component.send(:final_options)
      expect(options).not_to have_key(:form)
    end
  end

  describe "#loading_spinner" do
    it "returns nil when not loading" do
      component = described_class.new(text: "Test", loading: false)
      expect(component.send(:loading_spinner)).to be_nil
    end

    it "returns SVG markup when loading" do
      component = described_class.new(text: "Test", loading: true)
      render_inline(component) # Ensure view context
      spinner = component.send(:loading_spinner)
      expect(spinner).to include("svg")
      expect(spinner).to include("btn-spinner")
    end
  end

  describe "content block vs text parameter" do
    it "renders with text parameter" do
      component = described_class.new(text: "Text Parameter")
      rendered = render_inline(component)
      expect(rendered.to_html).to include("Text Parameter")
    end

    it "renders with content block" do
      rendered = render_inline(described_class.new(text: "Ignored")) { "Block Content" }
      expect(rendered.to_html).to include("Block Content")
      expect(rendered.to_html).not_to include("Ignored")
    end

    it "prefers content block over text parameter" do
      rendered = render_inline(described_class.new(text: "Text")) { "Block" }
      expect(rendered.to_html).to include("Block")
      expect(rendered.to_html).not_to include("Text")
    end
  end

  describe "link rendering" do
    it "renders as link when url is provided" do
      component = described_class.new(text: "Link", url: "/path")
      rendered = render_inline(component)
      expect(rendered.css('a[href="/path"]')).to be_present
    end

    it "renders link with turbo-method for delete" do
      component = described_class.new(text: "Delete", url: "/path", method: :delete)
      rendered = render_inline(component)
      expect(rendered.css('a[data-turbo-method="delete"]')).to be_present
    end

    it "renders link with turbo-method for post" do
      component = described_class.new(text: "Create", url: "/path", method: :post)
      rendered = render_inline(component)
      expect(rendered.css('a[data-turbo-method="post"]')).to be_present
    end

    it "renders link with turbo-method for patch" do
      component = described_class.new(text: "Update", url: "/path", method: :patch)
      rendered = render_inline(component)
      expect(rendered.css('a[data-turbo-method="patch"]')).to be_present
    end

    it "does not add turbo-method for get requests" do
      component = described_class.new(text: "View", url: "/path", method: :get)
      rendered = render_inline(component)
      expect(rendered.css('a[data-turbo-method]')).to be_empty
    end

    it "renders link with loading spinner" do
      component = described_class.new(text: "Loading Link", url: "/path", loading: true)
      rendered = render_inline(component)
      expect(rendered.css('a svg.btn-spinner')).to be_present
    end

    it "renders link with custom data attributes" do
      component = described_class.new(
        text: "Link",
        url: "/path",
        data: { turbo_confirm: "Are you sure?" }
      )
      rendered = render_inline(component)
      expect(rendered.css('a[data-turbo-confirm="Are you sure?"]')).to be_present
    end

    it "combines turbo-method with other data attributes" do
      component = described_class.new(
        text: "Delete",
        url: "/path",
        method: :delete,
        data: { turbo_confirm: "Delete?" }
      )
      rendered = render_inline(component)
      expect(rendered.css('a[data-turbo-method="delete"]')).to be_present
      expect(rendered.css('a[data-turbo-confirm="Delete?"]')).to be_present
    end
  end

  describe "data attributes" do
    it "renders with single data attribute" do
      component = described_class.new(
        text: "Test",
        data: { action: "click->modal#open" }
      )
      rendered = render_inline(component)
      expect(rendered.css('button[data-action="click->modal#open"]')).to be_present
    end

    it "renders with multiple data attributes" do
      component = described_class.new(
        text: "Test",
        data: {
          controller: "clipboard",
          action: "click->clipboard#copy",
          clipboard_text_value: "Hello"
        }
      )
      rendered = render_inline(component)
      expect(rendered.css('button[data-controller="clipboard"]')).to be_present
      expect(rendered.css('button[data-action="click->clipboard#copy"]')).to be_present
      expect(rendered.css('button[data-clipboard-text-value="Hello"]')).to be_present
    end
  end

  describe "additional HTML options" do
    it "renders with id attribute" do
      component = described_class.new(text: "Test", id: "my-button")
      rendered = render_inline(component)
      expect(rendered.css('button#my-button')).to be_present
    end

    it "renders with title attribute" do
      component = described_class.new(text: "Test", title: "Tooltip text")
      rendered = render_inline(component)
      expect(rendered.css('button[title="Tooltip text"]')).to be_present
    end

    it "renders with aria attributes" do
      component = described_class.new(
        text: "Test",
        "aria-expanded": "false",
        "aria-controls": "dropdown"
      )
      rendered = render_inline(component)
      expect(rendered.css('button[aria-expanded="false"]')).to be_present
      expect(rendered.css('button[aria-controls="dropdown"]')).to be_present
    end
  end

  describe "integration scenarios" do
    it "handles complex combination of features" do
      component = described_class.new(
        text: "Complex Button",
        variant: :primary,
        size: :lg,
        full_width: true,
        loading: true,
        classes: "custom-class",
        data: { action: "click->test#method", value: "123" },
        title: "Tooltip",
        id: "complex-btn"
      )
      rendered = render_inline(component)

      expect(rendered.css('button#complex-btn.btn.btn-primary.btn-lg.btn-full-width.loading.custom-class')).to be_present
      expect(rendered.css('button[data-action="click->test#method"]')).to be_present
      expect(rendered.css('button[data-value="123"]')).to be_present
      expect(rendered.css('button[title="Tooltip"]')).to be_present
      expect(rendered.css('button svg.btn-spinner')).to be_present
    end

    it "handles link with all features" do
      component = described_class.new(
        text: "Complex Link",
        url: "/path",
        method: :post,
        variant: :danger,
        size: :sm,
        data: { turbo_confirm: "Sure?" },
        classes: "link-class"
      )
      rendered = render_inline(component)

      expect(rendered.css('a.btn.btn-danger.btn-sm.link-class')).to be_present
      expect(rendered.css('a[href="/path"]')).to be_present
      expect(rendered.css('a[data-turbo-method="post"]')).to be_present
      expect(rendered.css('a[data-turbo-confirm="Sure?"]')).to be_present
    end

    it "handles disabled and loading together" do
      component = described_class.new(
        text: "Test",
        disabled: true,
        loading: true
      )
      rendered = render_inline(component)
      classes = component.send(:button_classes)

      expect(classes).to include('disabled')
      expect(classes).to include('loading')
      expect(rendered.css('button[disabled]')).to be_present
      expect(rendered.css('button svg.btn-spinner')).to be_present
    end

    it "handles submit button with form attribute" do
      component = described_class.new(
        text: "Submit External Form",
        type: :submit,
        form: "external-form",
        variant: :success
      )
      rendered = render_inline(component)

      expect(rendered.css('button[type="submit"]')).to be_present
      expect(rendered.css('button[form="external-form"]')).to be_present
      expect(rendered.css('button.btn-success')).to be_present
    end

    it "handles form builder submit" do
      form = mock_form_builder
      component = described_class.new(
        text: "Submit",
        form: form,
        variant: :primary
      )
      rendered = render_inline(component)

      expect(rendered.css('input[type="submit"]')).to be_present
      expect(rendered.css('input.btn-primary')).to be_present
    end
  end
end
