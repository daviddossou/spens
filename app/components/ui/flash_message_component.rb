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

  def icon_for_type(type)
    case type
    when :notice, :success
      "✅"
    when :alert, :error
      "❌"
    when :warning
      "⚠️"
    when :info
      "ℹ️"
    else
      ""
    end
  end
end
