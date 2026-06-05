# frozen_string_literal: true

class Ui::FlashMessageComponent < ViewComponent::Base
  def initialize(flash_hash)
    @flash_hash = flash_hash
  end

  private

  attr_reader :flash_hash

  def flash_messages
    flash_hash.map do |type, message|
      {
        type: type.to_sym,
        message: message,
        classes: classes_for_type(type.to_sym)
      }
    end
  end

  def classes_for_type(type)
    base_classes = "flash-message"

    case type
    when :notice, :success
      "#{base_classes} flash-message-success"
    when :alert, :error
      "#{base_classes} flash-message-error"
    when :warning
      "#{base_classes} flash-message-warning"
    when :info
      "#{base_classes} flash-message-info"
    else
      "#{base_classes} flash-message-default"
    end
  end

  # Inline stroke icons (consistent with the app's icon style), not emoji.
  def icon_for_type(type)
    paths =
      case type
      when :notice, :success
        [ "M22 11.08V12a10 10 0 1 1-5.93-9.14", "M22 4 12 14.01l-3-3" ]
      when :alert, :error
        [ "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z", "M15 9l-6 6", "M9 9l6 6" ]
      when :warning
        [ "M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z", "M12 9v4", "M12 17h.01" ]
      when :info
        [ "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z", "M12 16v-4", "M12 8h.01" ]
      else
        return nil
      end

    inner = safe_join(paths.map { |d| tag.path(d: d) })
    tag.svg(inner, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
            "stroke-width": "2", "stroke-linecap": "round", "stroke-linejoin": "round")
  end

  def dismiss_icon
    inner = safe_join([ tag.path(d: "M18 6 6 18"), tag.path(d: "m6 6 12 12") ])
    tag.svg(inner, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
            "stroke-width": "2", "stroke-linecap": "round", "stroke-linejoin": "round")
  end
end
