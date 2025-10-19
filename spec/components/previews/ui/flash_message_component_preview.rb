# frozen_string_literal: true

class Ui::FlashMessageComponentPreview < ViewComponent::Preview
  def default
    flash_hash = {
      notice: "Operation completed successfully!",
      alert: "Something went wrong. Please try again."
    }

    render Ui::FlashMessageComponent.new(flash_hash)
  end

  def all_types
    flash_hash = {
      notice: "This is a success notice message",
      alert: "This is an alert/error message",
      warning: "This is a warning message",
      info: "This is an informational message",
      success: "This is a success message",
      error: "This is an error message",
      custom: "This is a custom message type"
    }

    render Ui::FlashMessageComponent.new(flash_hash)
  end

  def success_only
    flash_hash = { notice: "Your profile has been updated successfully!" }

    render Ui::FlashMessageComponent.new(flash_hash)
  end

  def error_only
    flash_hash = { alert: "Invalid email or password. Please check your credentials and try again." }

    render Ui::FlashMessageComponent.new(flash_hash)
  end

  def warning_only
    flash_hash = { warning: "Your session will expire in 5 minutes. Please save your work." }

    render Ui::FlashMessageComponent.new(flash_hash)
  end

  def info_only
    flash_hash = { info: "A verification email has been sent to your address. Please check your inbox." }

    render Ui::FlashMessageComponent.new(flash_hash)
  end

  def long_messages
    flash_hash = {
      notice: "This is a very long success message that demonstrates how the flash message component handles longer text content. It should wrap properly and maintain good readability while providing enough space for detailed information.",
      alert: "This is a very long error message that shows how error messages are displayed when they contain multiple sentences and detailed explanations about what went wrong and what the user should do to fix the issue."
    }

    render Ui::FlashMessageComponent.new(flash_hash)
  end

  def empty_flash
    flash_hash = {}

    render Ui::FlashMessageComponent.new(flash_hash)
  end

  def multiple_same_type
    flash_hash = {
      notice: "First success message",
      alert: "First error message"
    }

    render Ui::FlashMessageComponent.new(flash_hash)
  end

  def custom_types
    flash_hash = {
      debug: "This is a debug message (custom type)",
      custom: "This is a custom message type"
    }

    render Ui::FlashMessageComponent.new(flash_hash)
  end
end
