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
      base_classes,
      variant_classes,
      size_classes,
      width_classes,
      state_classes,
      classes
    ].compact.join(" ")
  end

  def base_classes
    "inline-flex items-center justify-center border rounded-md shadow-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors"
  end

  def variant_classes
    case variant
    when :primary
      "bg-primary border-transparent text-white hover:bg-secondary focus:ring-primary"
    when :secondary
      "bg-secondary border-transparent text-white hover:bg-primary focus:ring-secondary"
    when :danger
      "bg-danger border-transparent text-white hover:bg-danger-700 focus:ring-danger-500"
    when :success
      "bg-success border-transparent text-white hover:bg-success-700 focus:ring-success-500"
    when :warning
      "bg-warning border-transparent text-white hover:bg-warning-700 focus:ring-warning-500"
    when :outline
      "bg-transparent border-primary text-primary hover:bg-primary hover:text-white focus:ring-primary"
    else
      variant_classes_for(:primary)
    end
  end

  def size_classes
    case size
    when :xs
      "px-2.5 py-1.5 text-xs"
    when :sm
      "px-3 py-2 text-sm"
    when :md
      "px-4 py-2 text-sm"
    when :lg
      "px-4 py-2 text-base"
    when :xl
      "px-6 py-3 text-base"
    else
      "px-4 py-2 text-sm"
    end
  end

  def width_classes
    full_width ? "w-full flex" : ""
  end

  def state_classes
    classes = []
    classes << "opacity-75 cursor-not-allowed" if disabled
    classes << "opacity-75" if loading
    classes.join(" ")
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

    content_tag :svg, class: "animate-spin -ml-1 mr-3 h-5 w-5 text-white", fill: "none", viewBox: "0 0 24 24" do
      concat tag(:circle, class: "opacity-25", cx: "12", cy: "12", r: "10", stroke: "currentColor", "stroke-width": "4")
      concat tag(:path, class: "opacity-75", fill: "currentColor", d: "M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z")
    end
  end
end
