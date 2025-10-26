# frozen_string_literal: true

class Ui::SelectableCardComponent < ViewComponent::Base
  def initialize(
    item:,
    form:,
    field:,
    selected: false,
    css_class: "card",
    description_classes: nil,
    show_visual_checkbox: true,
    **html_options
  )
    @item = item
    @form = form
    @field = field
    @selected = selected
    @css_class = css_class
    @description_classes = description_classes
    @show_visual_checkbox = show_visual_checkbox
    @html_options = html_options
  end

  private

  attr_reader :item, :form, :field, :selected, :css_class, :description_classes, :show_visual_checkbox, :html_options

  def selected?
    selected
  end

  def root_classes
    return css_class unless selected?
    "#{css_class} selected"
  end

  def final_html_options
    options = html_options.dup
    options[:class] = [options[:class], root_classes].compact.join(' ')

    # Add Stimulus controller for toggle behavior
    options[:data] ||= {}
    options[:data][:controller] = [options[:data][:controller], 'ui--selectable-card'].compact.join(' ')
    options[:data][:action] = [options[:data][:action], 'click->ui--selectable-card#toggle'].compact.join(' ')

    options
  end

  def checkbox_options
    {
      form: form,
      field: field,
      value: item_value,
      multiple: true,
      checked: selected?,
      hide_label: true,
      wrapper_classes: 'hidden',
      data: { 'ui--selectable-card-target': 'checkbox' }
    }
  end

  def content_section_classes
    "#{css_class}-content"
  end

  def checkbox_section_classes
    "#{css_class}-checkbox"
  end

  def render_visual_checkbox?
    show_visual_checkbox
  end

  def item_name
    return item if item.is_a?(String)
    item[:name] || item['name'] || (item.respond_to?(:name) ? item.name : item.to_s)
  end

  def item_description
    return nil if item.is_a?(String)
    item[:description] || item['description'] || (item.respond_to?(:description) ? item.description : nil)
  end

  def item_value
    return item_name if item.is_a?(String)

    # Try hash-style access first
    return item[:key] if item.is_a?(Hash) && item.key?(:key)
    return item['key'] if item.is_a?(Hash) && item.key?('key')
    return item[:value] if item.is_a?(Hash) && item.key?(:value)
    return item['value'] if item.is_a?(Hash) && item.key?('value')

    # Try method access for objects/structs
    return item.id if item.respond_to?(:id)
    return item.key if item.respond_to?(:key)
    return item.value if item.respond_to?(:value)

    # Fallback to name
    item_name
  end
end
