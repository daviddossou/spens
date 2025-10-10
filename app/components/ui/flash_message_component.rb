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
    base_classes = "mb-4 p-4 border rounded-md"

    case type
    when :notice, :success
      "#{base_classes} bg-success-50 border-success text-success"
    when :alert, :error
      "#{base_classes} bg-danger-50 border-danger text-danger"
    when :warning
      "#{base_classes} bg-warning-50 border-warning text-warning"
    when :info
      "#{base_classes} bg-info-50 border-info text-info"
    else
      "#{base_classes} bg-gray-50 border-gray-200 text-gray-800"
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
