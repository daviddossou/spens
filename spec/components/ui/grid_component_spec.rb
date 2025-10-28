# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ui::GridComponent, type: :component do
  describe 'basic grid rendering' do
    it 'renders empty grid with default classes' do
      rendered = render_inline(described_class.new)

      expect(rendered.css('div').first['class']).to eq('grid grid-auto-fit')
      expect(rendered.to_html).not_to include('style=')
    end

    it 'renders grid with custom CSS class' do
      rendered = render_inline(described_class.new(css_class: 'custom-grid'))

      expect(rendered.css('div').first['class']).to eq('custom-grid grid-auto-fit')
    end
  end

  describe 'column-based grids' do
    it 'renders 2-column grid' do
      rendered = render_inline(described_class.new(columns: 2))

      expect(rendered.css('div').first['class']).to eq('grid grid-2')
    end

    it 'renders 4-column grid' do
      rendered = render_inline(described_class.new(columns: 4))

      expect(rendered.css('div').first['class']).to eq('grid grid-4')
    end

    it 'handles string column values' do
      rendered = render_inline(described_class.new(columns: '3'))

      expect(rendered.css('div').first['class']).to eq('grid grid-3')
    end
  end

  describe 'auto-fit grid' do
    it 'uses auto-fit when no columns specified' do
      rendered = render_inline(described_class.new)

      expect(rendered.css('div').first['class']).to include('grid-auto-fit')
    end

    it 'uses auto-fit when columns is nil' do
      rendered = render_inline(described_class.new(columns: nil))

      expect(rendered.css('div').first['class']).to include('grid-auto-fit')
    end
  end

  describe 'CSS custom properties' do
    it 'does not add style attribute for default gap' do
      rendered = render_inline(described_class.new(gap: '1rem'))

      expect(rendered.to_html).not_to include('style=')
    end

    it 'adds custom gap as CSS variable' do
      rendered = render_inline(described_class.new(gap: '2rem'))

      expect(rendered.css('div').first['style']).to include('--grid-gap: 2rem')
    end

    it 'does not add style attribute for default min_width' do
      rendered = render_inline(described_class.new(min_width: '300px'))

      expect(rendered.to_html).not_to include('style=')
    end

    it 'adds custom min_width as CSS variable' do
      rendered = render_inline(described_class.new(min_width: '250px'))

      expect(rendered.css('div').first['style']).to include('--grid-min-width: 250px')
    end

    it 'combines multiple custom properties' do
      rendered = render_inline(described_class.new(gap: '1.5rem', min_width: '280px'))

      style = rendered.css('div').first['style']
      expect(style).to include('--grid-gap: 1.5rem')
      expect(style).to include('--grid-min-width: 280px')
    end
  end

  describe 'HTML options' do
    it 'merges additional HTML options' do
      rendered = render_inline(described_class.new(id: 'my-grid', data: { controller: 'grid' }))

      div = rendered.css('div').first
      expect(div['id']).to eq('my-grid')
      expect(div['data-controller']).to eq('grid')
    end

    it 'combines custom class with existing classes' do
      rendered = render_inline(described_class.new(
        columns: 2,
        class: 'additional-class'
      ))

      expect(rendered.css('div').first['class']).to eq('grid grid-2 additional-class')
    end

    it 'combines custom style with CSS custom properties' do
      rendered = render_inline(described_class.new(
        gap: '2rem',
        style: 'background: red'
      ))

      style = rendered.css('div').first['style']
      expect(style).to include('--grid-gap: 2rem')
      expect(style).to include('background: red')
    end
  end

  describe 'item rendering' do
    it 'renders empty grid when no items provided' do
      rendered = render_inline(described_class.new)

      expect(rendered.css('div > *')).to be_empty
    end

    it 'returns empty array when item_component is not specified' do
      items = [ { name: 'Item 1' } ]

      rendered = render_inline(described_class.new(items: items))

      expect(rendered.css('div > *')).to be_empty
    end

    it 'handles empty items array with component specified' do
      # Test the rendered_items method behavior
      component = described_class.new(
        items: [],
        item_component: Ui::ButtonComponent
      )

      expect(component.send(:rendered_items)).to eq([])
    end

    it 'processes items when both items and component are provided' do
      # Test the basic logic of rendered_items method without actual rendering
      items = [ { name: 'Item 1' }, { name: 'Item 2' } ]

      component = described_class.new(
        items: items,
        item_component: Ui::ButtonComponent
      )

      # Mock the render method to avoid actual rendering issues
      allow(component).to receive(:render).and_return('mocked render')

      rendered_items = component.send(:rendered_items)
      expect(rendered_items.length).to eq(2)
      expect(rendered_items).to all(eq('mocked render'))
    end
  end

  describe 'edge cases' do
    it 'handles zero columns' do
      rendered = render_inline(described_class.new(columns: 0))

      expect(rendered.css('div').first['class']).to eq('grid grid-0')
    end

    it 'handles empty string gap' do
      rendered = render_inline(described_class.new(gap: ''))

      expect(rendered.css('div').first['style']).to include('--grid-gap: ')
    end

    it 'handles nil CSS class' do
      rendered = render_inline(described_class.new(css_class: nil))

      expect(rendered.css('div').first['class']).to eq('grid-auto-fit')
    end

    it 'handles empty items array' do
      rendered = render_inline(described_class.new(
        items: []
      ))

      expect(rendered.css('div > *')).to be_empty
    end
  end

  describe 'integration scenarios' do
    it 'creates a complete 3-column grid with custom styling' do
      rendered = render_inline(described_class.new(
        columns: 3,
        gap: '1.5rem',
        css_class: 'cards-grid',
        id: 'main-grid'
      ))

      div = rendered.css('div').first
      expect(div['class']).to eq('cards-grid grid-3')
      expect(div['style']).to include('--grid-gap: 1.5rem')
      expect(div['id']).to eq('main-grid')
    end

    it 'generates proper CSS structure for auto-fit grid' do
      rendered = render_inline(described_class.new(
        min_width: '250px',
        gap: '2rem'
      ))

      div = rendered.css('div').first
      expect(div['class']).to eq('grid grid-auto-fit')
      expect(div['style']).to include('--grid-gap: 2rem')
      expect(div['style']).to include('--grid-min-width: 250px')
    end
  end
end
