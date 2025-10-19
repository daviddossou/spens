# frozen_string_literal: true

class Ui::ButtonComponent < ViewComponent::Base
  def initialize(
    text: nil,
    type: :button,
    variant: :primary,
    size: :md,
    disabled: false,
    loading: false,
    full_width: false,
    form: nil,
    url: nil,
    method: :get,
    classes: nil,
    data: {},
    **options
  )
    @text = text
    @type = type
    @variant = variant
    @size = size
    @disabled = disabled
    @loading = loading
    @full_width = full_width
    @form = form
    @url = url
    @method = method
    @classes = classes
    @data = data
    @options = options
  end

  private

  attr_reader :text, :type, :variant, :size, :disabled, :loading, :full_width,
              :form, :url, :method, :classes, :data, :options

  def button_classes
    [
      "btn",
      "btn-#{variant}",
      "btn-#{size}",
      full_width_class,
      state_classes,
      classes
    ].compact.join(" ")
  end

  def full_width_class
    full_width ? "btn-full-width" : nil
  end

  def state_classes
    state_list = []
    state_list << "disabled" if disabled
    state_list << "loading" if loading
    state_list.empty? ? nil : state_list.join(" ")
  end

  def is_submit?
    type == :submit || form.present?
  end

  def is_link?
    url.present?
  end

  def button_type
    return :submit if is_submit?
    return :button if type == :button
    type
  end

  def final_data
    base_data = data.dup
    base_data["turbo-method"] = method if is_link? && method != :get
    base_data
  end

  def final_options
    opts = options.dup
    opts[:disabled] = true if disabled
    opts[:class] = button_classes
    opts[:data] = final_data
    opts[:type] = button_type unless is_link?
    opts
  end

  def loading_spinner
    return unless loading

    content_tag :svg, class: "btn-spinner", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor" do
      concat tag(:circle, class: "opacity-25", cx: "12", cy: "12", r: "10", stroke: "currentColor", "stroke-width": "4")
      concat tag(:path, class: "opacity-75", fill: "currentColor", d: "M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z")
    end
  end
end
