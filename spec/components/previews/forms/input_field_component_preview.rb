# frozen_string_literal: true

class Forms::InputFieldComponentPreview < ViewComponent::Preview
  # Default input field
  # @param field_type select { choices: [text_field, email_field, password_field, number_field, url_field, telephone_field] }
  def default(field_type: :text_field)
    render_with_template locals: { field_type: field_type.to_sym }
  end

  # Required field with validation
  def required_field
    render_with_template
  end

  # Field with errors
  def with_errors
    user = User.new
    user.errors.add(:email, "can't be blank")
    user.errors.add(:email, "is invalid")

    render_with_template locals: { user: user }
  end

  # Different field types
  def field_types
    render_with_template locals: {
      field_types: [:text_field, :email_field, :password_field, :number_field, :url_field, :telephone_field]
    }
  end
end
