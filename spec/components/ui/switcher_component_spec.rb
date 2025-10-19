# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ui::SwitcherComponent, type: :component do
  let(:basic_options) do
    [
      { text: 'Option 1', value: 'opt1', url: '/opt1' },
      { text: 'Option 2', value: 'opt2', url: '/opt2' }
    ]
  end

  let(:language_options) do
    [
      { text: 'EN', value: 'en', url: '/en' },
      { text: 'ES', value: 'es', url: '/es' }
    ]
  end

  describe 'rendering' do
    it 'renders a basic switcher with all options' do
      rendered = render_inline(described_class.new(options: basic_options, current: 'opt1'))

      expect(rendered.to_html).to include('href="/opt1"')
      expect(rendered.to_html).to include('href="/opt2"')
      expect(rendered.to_html).to include('Option 1')
      expect(rendered.to_html).to include('Option 2')
    end

    it 'renders a language switcher' do
      rendered = render_inline(described_class.new(options: language_options, current: 'en'))

      expect(rendered.to_html).to include('href="/en"')
      expect(rendered.to_html).to include('href="/es"')
      expect(rendered.to_html).to include('EN')
      expect(rendered.to_html).to include('ES')
    end

    it 'renders links as anchor tags' do
      rendered = render_inline(described_class.new(options: basic_options, current: 'opt1'))

      expect(rendered.css('a').count).to eq(2)
    end

    it 'renders all options even when no current is selected' do
      rendered = render_inline(described_class.new(options: basic_options))

      expect(rendered.css('a').count).to eq(2)
    end
  end

  describe 'CSS classes' do
    it 'applies switcher class to container' do
      rendered = render_inline(described_class.new(options: basic_options, current: 'opt1'))

      expect(rendered.css('div.switcher').count).to eq(1)
    end

    it 'applies switcher-option class to all options' do
      rendered = render_inline(described_class.new(options: basic_options, current: 'opt1'))

      rendered.css('a').each do |link|
        expect(link['class']).to include('switcher-option')
      end
    end

    it 'applies active class to current option' do
      rendered = render_inline(described_class.new(options: language_options, current: 'en'))

      active_link = rendered.css('a').find { |link| link.text.strip == 'EN' }
      expect(active_link['class']).to include('active')
    end

    it 'does not apply active class to non-current options' do
      rendered = render_inline(described_class.new(options: language_options, current: 'en'))

      inactive_link = rendered.css('a').find { |link| link.text.strip == 'ES' }
      expect(inactive_link['class']).not_to include('active')
    end

    it 'allows custom CSS class via css_class parameter' do
      rendered = render_inline(described_class.new(options: basic_options, current: 'opt1', css_class: 'custom-switcher'))

      expect(rendered.css('div').first['class']).to include('custom-switcher')
    end

    it 'preserves default switcher class when custom class is added' do
      rendered = render_inline(described_class.new(options: basic_options, current: 'opt1', css_class: 'custom-switcher'))

      expect(rendered.css('div').first['class']).to include('switcher')
      expect(rendered.css('div').first['class']).to include('custom-switcher')
    end
  end

  describe 'option handling' do
    it 'handles hash options with text and value keys' do
      options = [{ text: 'Label', value: 'val', url: '/path' }]
      rendered = render_inline(described_class.new(options: options, current: 'val'))

      expect(rendered.to_html).to include('Label')
      expect(rendered.css('a.active').count).to eq(1)
    end

    it 'handles hash options with string keys' do
      options = [{ 'text' => 'Label', 'value' => 'val', 'url' => '/path' }]
      rendered = render_inline(described_class.new(options: options, current: 'val'))

      expect(rendered.to_html).to include('Label')
    end

    it 'uses label as fallback for text' do
      options = [{ label: 'My Label', value: 'val', url: '/path' }]
      rendered = render_inline(described_class.new(options: options, current: 'val'))

      expect(rendered.to_html).to include('My Label')
    end

    it 'defaults to # for missing url' do
      options = [{ text: 'Option', value: 'opt' }]
      rendered = render_inline(described_class.new(options: options))

      expect(rendered.to_html).to include('href="#"')
    end

    it 'handles data attributes' do
      options = [{ text: 'Option', value: 'opt', url: '/path', data: { turbo: false, action: 'click' } }]
      rendered = render_inline(described_class.new(options: options))

      link = rendered.css('a').first
      expect(link['data-turbo']).to eq('false')
      expect(link['data-action']).to eq('click')
    end
  end

  describe 'HTML options' do
    it 'accepts additional HTML options' do
      rendered = render_inline(described_class.new(options: basic_options, current: 'opt1', id: 'my-switcher'))

      expect(rendered.css('div#my-switcher').count).to eq(1)
    end

    it 'merges custom class with css_class parameter' do
      rendered = render_inline(described_class.new(options: basic_options, current: 'opt1', class: 'extra-class'))

      container_class = rendered.css('div').first['class']
      expect(container_class).to include('switcher')
      expect(container_class).to include('extra-class')
    end

    it 'accepts data attributes on container' do
      rendered = render_inline(described_class.new(options: basic_options, current: 'opt1', data: { controller: 'switcher' }))

      expect(rendered.css('div').first['data-controller']).to eq('switcher')
    end
  end

  describe 'current selection logic' do
    it 'marks the correct option as active' do
      rendered = render_inline(described_class.new(options: basic_options, current: 'opt2'))

      active_link = rendered.css('a.active').first
      expect(active_link.text.strip).to eq('Option 2')
    end

    it 'handles nil current value' do
      rendered = render_inline(described_class.new(options: basic_options, current: nil))

      expect(rendered.css('a.active').count).to eq(0)
    end

    it 'handles empty string current value' do
      rendered = render_inline(described_class.new(options: basic_options, current: ''))

      expect(rendered.css('a.active').count).to eq(0)
    end

    it 'compares current with option value, not text' do
      options = [{ text: 'English', value: 'en', url: '/en' }]
      rendered = render_inline(described_class.new(options: options, current: 'en'))

      expect(rendered.css('a.active').count).to eq(1)
    end
  end

  describe 'edge cases' do
    it 'handles empty options array' do
      rendered = render_inline(described_class.new(options: [], current: nil))

      expect(rendered.css('div.switcher').count).to eq(1)
      expect(rendered.css('a').count).to eq(0)
    end

    it 'handles single option' do
      options = [{ text: 'Only Option', value: 'only', url: '/only' }]
      rendered = render_inline(described_class.new(options: options, current: 'only'))

      expect(rendered.css('a').count).to eq(1)
      expect(rendered.css('a.active').count).to eq(1)
    end

    it 'handles many options' do
      many_options = 10.times.map { |i| { text: "Option #{i}", value: "opt#{i}", url: "/opt#{i}" } }
      rendered = render_inline(described_class.new(options: many_options, current: 'opt5'))

      expect(rendered.css('a').count).to eq(10)
      expect(rendered.css('a.active').count).to eq(1)
    end
  end
end
