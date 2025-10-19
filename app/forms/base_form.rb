# frozen_string_literal: true

class BaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  private

    def promote_errors(child_errors)
      child_errors.each do |attribute, message|
        errors.add(attribute, message.first)
      end
    end

    def add_custom_error(attribute, message)
      errors.add(attribute, message)
    end
end
