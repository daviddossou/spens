# frozen_string_literal: true

class Ui::SwitcherComponent < ViewComponent::Base
  def initialize(
    options: [],
    current: nil,
    css_class: "switcher",
    **html_options
  )
    @options = options
    @current = current
    @css_class = css_class
    @html_options = html_options
  end

  private

  attr_reader :options, :current, :css_class, :html_options

  def final_html_options
    opts = html_options.dup
    opts[:class] = [ css_class, opts[:class] ].compact.join(" ")
    opts
  end

  def option_classes(option)
    if is_current?(option)
      "switcher-option active"
    else
      "switcher-option"
    end
  end

  def is_current?(option)
    if option.is_a?(Hash)
      option_value = option[:value] || option["value"]
    else
      option_value = option
    end

    current == option_value
  end

  def option_text(option)
    if option.is_a?(Hash)
      option[:text] || option["text"] || option[:label] || option["label"] || option_value(option).to_s
    else
      option.to_s
    end
  end

  def option_value(option)
    if option.is_a?(Hash)
      option[:value] || option["value"] || option[:text] || option["text"]
    else
      option
    end
  end

  def option_url(option)
    if option.is_a?(Hash)
      option[:url] || option["url"] || "#"
    else
      "#"
    end
  end

  def option_data(option)
    if option.is_a?(Hash)
      option[:data] || option["data"] || {}
    else
      {}
    end
  end
end
