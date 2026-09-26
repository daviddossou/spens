# frozen_string_literal: true

class BaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  # Raised inside submit with a message that is safe to show to the user.
  class UserFacingError < StandardError; end

  private

    # Copies a child's errors onto the form. An ActiveModel::Errors object keeps
    # its full sentences; a plain { attribute => [messages] } hash is taken as-is.
    def promote_errors(child_errors)
      if child_errors.is_a?(ActiveModel::Errors)
        child_errors.each { |error| errors.add(error.attribute, error.full_message) }
      else
        child_errors.each { |attribute, messages| errors.add(attribute, Array(messages).first) }
      end
    end

    def add_custom_error(attribute, message)
      errors.add(attribute, message)
    end

    # Technical failures are logged in full; the user only sees a generic message,
    # unless the error was raised with wording meant for them.
    def handle_submit_error(error)
      Rails.logger.error "#{self.class.name} submit error: #{error.message}\n#{Array(error.backtrace).join("\n")}"
      message = error.is_a?(UserFacingError) ? error.message : I18n.t("errors.messages.unexpected")
      errors.add(:base, message)
      false
    end
end
