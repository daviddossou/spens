# frozen_string_literal: true

class Forms::InputFieldComponentPreview < ViewComponent::Preview
  # Default input field
  # @param field_type select { choices: [text_field, email_field, password_field, number_field, url_field, tel_field] }
  def default(field_type: :text_field)
    form = MockForm.new

    render Forms::InputFieldComponent.new(
      form: form,
      field: :sample_field,
      type: field_type.to_sym,
      label: "Sample #{field_type.to_s.humanize}",
      help_text: "This is a help text example"
    )
  end

  # Required field with validation
  def required_field
    form = MockForm.new

    render Forms::InputFieldComponent.new(
      form: form,
      field: :required_field,
      type: :email_field,
      label: "Required Email",
      required: true,
      help_text: "This field is required"
    )
  end

  # Field with errors
  def with_errors
    form = MockFormWithErrors.new

    render Forms::InputFieldComponent.new(
      form: form,
      field: :email,
      type: :email_field,
      label: "Email with Error",
      required: true
    )
  end

  # Different field types
  def field_types
    form = MockForm.new
    field_types = [:text_field, :email_field, :password_field, :number_field, :url_field, :tel_field]

    render_with_template locals: { form: form, field_types: field_types }
  end

  private

  # Mock form object for previews
  class MockForm
    def object
      MockObject.new
    end

    def text_field(field, options = {})
      "<input type='text' name='#{field}' class='#{options[:class]}' />".html_safe
    end

    def email_field(field, options = {})
      "<input type='email' name='#{field}' class='#{options[:class]}' />".html_safe
    end

    def password_field(field, options = {})
      "<input type='password' name='#{field}' class='#{options[:class]}' />".html_safe
    end

    def number_field(field, options = {})
      "<input type='number' name='#{field}' class='#{options[:class]}' />".html_safe
    end

    def url_field(field, options = {})
      "<input type='url' name='#{field}' class='#{options[:class]}' />".html_safe
    end

    def tel_field(field, options = {})
      "<input type='tel' name='#{field}' class='#{options[:class]}' />".html_safe
    end

    def label(field, text, options = {})
      "<label class='#{options[:class]}'>#{text}</label>".html_safe
    end
  end

  class MockObject
    def errors
      MockErrors.new
    end
  end

  class MockErrors
    def key?(field)
      false
    end

    def full_messages_for(field)
      []
    end
  end

  # Mock form with errors for error state preview
  class MockFormWithErrors < MockForm
    class MockObjectWithErrors < MockObject
      class MockErrorsWithErrors < MockErrors
        def key?(field)
          field == :email
        end

        def full_messages_for(field)
          return ["Email can't be blank", "Email is invalid"] if field == :email
          []
        end
      end

      def errors
        MockErrorsWithErrors.new
      end
    end

    def object
      MockObjectWithErrors.new
    end
  end
end
