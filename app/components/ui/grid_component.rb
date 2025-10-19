# frozen_string_literal: true

class Ui::GridComponent < ViewComponent::Base
  def initialize(
    items: [],
    columns: nil,
    gap: "1rem",
    min_width: "300px",
    css_class: "grid",
    item_component: nil,
    item_component_options: {},
    **html_options
  )
    @items = items
    @columns = columns
    @gap = gap
    @min_width = min_width
    @css_class = css_class
    @item_component = item_component
    @item_component_options = item_component_options
    @html_options = html_options
  end

  private

  attr_reader :items, :columns, :gap, :min_width, :css_class, :item_component, :item_component_options, :html_options

  def grid_classes
    classes = []
    classes << css_class if css_class.present?

    if columns
      classes << "grid-#{columns}"
    else
      classes << "grid-auto-fit"
    end

    classes
  end

  def css_custom_properties
    properties = {}
    properties['--grid-gap'] = gap unless gap == "1rem" # default
    properties['--grid-min-width'] = min_width unless min_width == "300px" # default
    properties
  end

  def final_html_options
    options = html_options.dup
    options[:class] = [grid_classes, options[:class]].compact.flatten.join(' ')

    if css_custom_properties.any?
      style_props = css_custom_properties.map { |prop, value| "#{prop}: #{value}" }.join('; ')
      options[:style] = [style_props, options[:style]].compact.join('; ')
    end

    options
  end

  def rendered_items
    return [] if items.empty? || !item_component

    items.map do |item|
      render item_component.new(item: item, **item_component_options)
    end
  end
end
