# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Navigation::LanguageSwitcherComponent, type: :component do
  let(:component) { described_class.new }

  before do
    # Mock link_to helper globally for all tests to avoid routing issues
    allow_any_instance_of(described_class).to receive(:link_to) do |instance, text, url, options|
      css_class = options[:class] || ""
      %(<a href="/test" class="#{css_class}">#{text}</a>).html_safe
    end
  end

  it_behaves_like "a rendered component" do
    subject(:rendered_component) { render_inline(component) }
  end

  describe "initialization" do
    it "uses default values when no parameters provided" do
      expect(component).to be_instance_of(Navigation::LanguageSwitcherComponent)
    end

    context "with custom parameters" do
      let(:component) do
        described_class.new(
          current_locale: :fr,
          available_locales: [ :en, :fr, :es ],
          params: { page: 1 }
        )
      end

      it "uses custom configuration" do
        expect(component.send(:current_locale)).to eq(:fr)
        expect(component.send(:available_locales)).to eq([ :en, :fr, :es ])
        expect(component.send(:params)).to eq({ page: 1 })
      end
    end
  end

  describe "link CSS class handling" do
    let(:component) { described_class.new(current_locale: :en, available_locales: [ :en, :fr ]) }

    context "for active locale" do
      it "applies active classes" do
        classes = component.send(:link_classes, :en)
        expect(classes).to include('bg-primary text-white')
      end
    end

    context "for inactive locale" do
      it "applies inactive classes" do
        classes = component.send(:link_classes, :fr)
        expect(classes).to include('bg-off-white text-gray-700')
        expect(classes).to include('hover:bg-primary hover:text-white')
      end
    end

    it "always includes base classes" do
      active_classes = component.send(:link_classes, :en)
      inactive_classes = component.send(:link_classes, :fr)

      [ active_classes, inactive_classes ].each do |classes|
        expect(classes).to include('px-2 py-1 text-xs rounded transition-colors')
      end
    end
  end

  describe "URL generation" do
    context "with ActionController::Parameters" do
      let(:strong_params) do
        # Mock ActionController::Parameters behavior
        double('ActionController::Parameters').tap do |params|
          allow(params).to receive(:respond_to?).with(:permit!).and_return(true)
          allow(params).to receive(:permit!).and_return(params)
          allow(params).to receive(:merge).with(locale: :fr).and_return({ locale: :fr, page: 1 })
        end
      end
      let(:component) { described_class.new(params: strong_params) }

      it "handles strong parameters correctly" do
        url = component.send(:locale_url, :fr)
        expect(url).to eq({ locale: :fr, page: 1 })
      end
    end

    context "with regular hash" do
      let(:component) { described_class.new(params: { page: 1 }) }

      it "merges locale with existing params" do
        url = component.send(:locale_url, :fr)
        expect(url).to eq({ page: 1, locale: :fr })
      end
    end

    context "with empty params" do
      let(:component) { described_class.new(params: {}) }

      it "returns only locale parameter" do
        url = component.send(:locale_url, :fr)
        expect(url).to eq({ locale: :fr })
      end
    end
  end

  describe "rendering behavior" do
    let(:available_locales) { [ :en, :fr ] }
    let(:component) do
      described_class.new(
        current_locale: :en,
        available_locales: available_locales,
        params: {}
      )
    end

    subject(:rendered) { render_inline(component) }

    it "renders container with correct structure" do
      expect(rendered.css('div')).to be_present
      expect(rendered.to_html).to include('flex space-x-2')
    end

    it "renders links for all available locales" do
      expect(rendered.css('a').count).to eq(available_locales.length)
    end

    it "displays locale codes in uppercase" do
      expect(rendered.to_html).to include('EN')
      expect(rendered.to_html).to include('FR')
    end

    context "with current locale highlighting" do
      it "applies different styles to current and other locales" do
        html_content = rendered.to_html
        expect(html_content).to include('EN')
        expect(html_content).to include('FR')
        expect(html_content).to include('bg-primary text-white')
        expect(html_content).to include('bg-off-white text-gray-700')
      end
    end

    context "with single locale" do
      let(:component) do
        described_class.new(
          current_locale: :en,
          available_locales: [ :en ],
          params: {}
        )
      end

      it "still renders the single locale" do
        expect(rendered.css('a').count).to eq(1)
        expect(rendered.to_html).to include('EN')
      end
    end

    context "with many locales" do
      let(:available_locales) { [ :en, :fr, :es, :de, :it ] }

      it "renders all locales" do
        expect(rendered.css('a').count).to eq(5)
      end
    end
  end

  describe "CSS class methods" do
    let(:component) { described_class.new }

    it "defines active classes correctly" do
      classes = component.send(:active_classes)
      expect(classes).to eq('bg-primary text-white')
    end

    it "defines inactive classes correctly" do
      classes = component.send(:inactive_classes)
      expect(classes).to eq('bg-off-white text-gray-700 hover:bg-primary hover:text-white')
    end
  end

  describe "edge cases" do
    context "with nil current_locale" do
      let(:component) { described_class.new(current_locale: nil, available_locales: [ :en, :fr ]) }

      it "handles nil current locale gracefully" do
        expect {
          component.send(:link_classes, :en)
        }.not_to raise_error
      end
    end

    context "with empty available_locales" do
      let(:component) { described_class.new(available_locales: []) }

      it "handles empty locales array" do
        expect(component.send(:available_locales)).to eq([])
      end
    end

    context "with symbol and string mixed locales" do
      let(:component) do
        described_class.new(
          current_locale: 'en',
          available_locales: [ :en, 'fr' ]
        )
      end

      it "handles mixed locale formats" do
        # Should work with both symbols and strings
        expect {
          component.send(:link_classes, :en)
          component.send(:link_classes, 'fr')
        }.not_to raise_error
      end
    end
  end
end
