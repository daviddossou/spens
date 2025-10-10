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
    let(:variants) { [:primary, :secondary, :danger, :success, :warning, :outline] }

    it "handles all supported variants" do
      variants.each do |variant|
        variant_component = described_class.new(text: "Test", variant: variant)
        classes = variant_component.send(:variant_classes)
        expect(classes).to be_present
      end
    end

    context "with primary variant" do
      let(:component) { described_class.new(text: "Test", variant: :primary) }

      it "applies primary classes" do
        classes = component.send(:variant_classes)
        expect(classes).to include('bg-primary')
        expect(classes).to include('text-white')
      end
    end

    context "with secondary variant" do
      let(:component) { described_class.new(text: "Test", variant: :secondary) }

      it "applies secondary classes" do
        classes = component.send(:variant_classes)
        expect(classes).to include('bg-secondary')
        expect(classes).to include('border-transparent')
        expect(classes).to include('text-white')
      end
    end
  end

  describe "size handling" do
    let(:sizes) { [:xs, :sm, :md, :lg, :xl] }

    it "handles all supported sizes" do
      sizes.each do |size|
        size_component = described_class.new(text: "Test", size: size)
        classes = size_component.send(:size_classes)
        expect(classes).to be_present
      end
    end

    context "with medium size" do
      let(:component) { described_class.new(text: "Test", size: :md) }

      it "applies medium size classes" do
        classes = component.send(:size_classes)
        expect(classes).to include('px-4 py-2')
      end
    end
  end

  describe "state handling" do
    context "when disabled" do
      let(:component) { described_class.new(text: "Test", disabled: true) }

      it "applies disabled styles" do
        classes = component.send(:state_classes)
        expect(classes).to include('opacity-75')
        expect(classes).to include('cursor-not-allowed')
      end
    end

    context "when loading" do
      let(:component) { described_class.new(text: "Test", loading: true) }

      it "applies loading styles" do
        classes = component.send(:state_classes)
        expect(classes).to include('opacity-75')
      end

      it "renders loading spinner" do
        spinner = component.send(:loading_spinner)
        expect(spinner).to be_present
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

    context "with form" do
      let(:form) { mock_form_builder }
      let(:component) { described_class.new(text: "Submit", form: form) }

      it "detects form submission" do
        expect(component.send(:is_submit?)).to be true
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

      it "shows loading spinner" do
        expect(rendered.to_html).to include('animate-spin')
      end
    end

    context "as form submit" do
      let(:form) { mock_form_builder }
      let(:component) { described_class.new(text: "Submit", form: form) }

      it "renders submit input" do
        expect(rendered.to_html).to include('type="submit"')
      end
    end

    context "with full width" do
      let(:component) { described_class.new(text: "Test", full_width: true) }

      it "applies full width classes" do
        expect(rendered.to_html).to include('w-full')
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
      expect(classes).to include('inline-flex') # base
      expect(classes).to include('bg-primary')  # variant
      expect(classes).to include('px-4 py-2')   # size
      expect(classes).to include('custom-class') # custom
    end
  end
end
