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
      "#{base_classes} bg-green-50 border-green-200 text-green-800"
    when :alert, :error
      "#{base_classes} bg-red-50 border-red-200 text-red-800"
    when :warning
      "#{base_classes} bg-yellow-50 border-yellow-200 text-yellow-800"
    when :info
      "#{base_classes} bg-blue-50 border-blue-200 text-blue-800"
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
