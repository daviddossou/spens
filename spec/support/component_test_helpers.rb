# frozen_string_literal: true

# Mock helpers for ViewComponent tests
module ComponentTestHelpers
  # Mock form builder for component testing
  class MockFormBuilder
    attr_reader :object

    def initialize(object = nil)
      @object = object || MockObject.new
    end

    # Form field methods
    def text_field(field, options = {})
      create_input_tag("text", field, options)
    end

    def email_field(field, options = {})
      create_input_tag("email", field, options)
    end

    def password_field(field, options = {})
      create_input_tag("password", field, options)
    end

    def number_field(field, options = {})
      create_input_tag("number", field, options)
    end

    def url_field(field, options = {})
      create_input_tag("url", field, options)
    end

    def tel_field(field, options = {})
      create_input_tag("tel", field, options)
    end

    def check_box(field, options = {})
      css_classes = options[:class] || ""
      %(<input type="checkbox" name="#{field}" class="#{css_classes}" />).html_safe
    end

    def label(field, text = nil, options = {})
      text ||= field.to_s.humanize
      css_classes = options[:class] || ""
      %(<label for="#{field}" class="#{css_classes}">#{text}</label>).html_safe
    end

    def submit(text, options = {})
      css_classes = options[:class] || ""
      %(<input type="submit" value="#{text}" class="#{css_classes}" />).html_safe
    end

    def public_send(method, *args)
      send(method, *args)
    end

    private

    def create_input_tag(type, field, options = {})
      css_classes = options[:class] || ""
      attributes = options.except(:class).map { |k, v| "#{k}=\"#{v}\"" }.join(" ")
      %(<input type="#{type}" name="#{field}" class="#{css_classes}" #{attributes} />).html_safe
    end
  end

  # Mock object for form testing
  class MockObject
    def errors
      @errors ||= MockErrors.new
    end
  end

  # Mock errors object
  class MockErrors
    def initialize(error_fields = {})
      @error_fields = error_fields
    end

    def key?(field)
      @error_fields.key?(field)
    end

    def full_messages_for(field)
      @error_fields[field] || []
    end
  end

  # Mock object with errors
  class MockObjectWithErrors < MockObject
    def errors
      @errors ||= MockErrors.new(
        email: ["Email can't be blank", "Email is invalid"],
        password: ["Password is too short"]
      )
    end
  end

  # Helper methods for creating mock objects
  def mock_form_builder(object = nil)
    MockFormBuilder.new(object)
  end

  def mock_form_with_errors
    MockFormBuilder.new(MockObjectWithErrors.new)
  end

  def mock_flash(messages = {})
    messages.with_indifferent_access
  end
end

RSpec.configure do |config|
  config.include ComponentTestHelpers, type: :component
end
