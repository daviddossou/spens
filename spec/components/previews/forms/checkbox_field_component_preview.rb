# frozen_string_literal: true

class Forms::CheckboxFieldComponentPreview < ViewComponent::Preview
  def default
    render Forms::CheckboxFieldComponent.new(
      form: mock_form_builder,
      field: :remember_me
    )
  end

  def custom_label
    render Forms::CheckboxFieldComponent.new(
      form: mock_form_builder,
      field: :terms_accepted,
      label: "I agree to the Terms of Service and Privacy Policy"
    )
  end

  def with_help_text
    render Forms::CheckboxFieldComponent.new(
      form: mock_form_builder,
      field: :newsletter_subscription,
      label: "Subscribe to our newsletter",
      help_text: "We'll send you updates about new features and important announcements. You can unsubscribe at any time."
    )
  end

  def with_errors
    render Forms::CheckboxFieldComponent.new(
      form: mock_form_with_errors,
      field: :email,
      label: "Email notifications"
    )
  end

  def hidden_label
    render Forms::CheckboxFieldComponent.new(
      form: mock_form_builder,
      field: :hidden_field,
      label: "This label is hidden",
      hide_label: true
    )
  end

  def multiple_unchecked
    render Forms::CheckboxFieldComponent.new(
      form: mock_form_builder,
      field: :financial_goals,
      label: "Save for emergency fund",
      value: "emergency_fund",
      multiple: true,
      checked: false
    )
  end

  def multiple_checked
    render Forms::CheckboxFieldComponent.new(
      form: mock_form_builder,
      field: :financial_goals,
      label: "Build retirement savings",
      value: "retirement",
      multiple: true,
      checked: true
    )
  end

  def custom_styling
    render Forms::CheckboxFieldComponent.new(
      form: mock_form_builder,
      field: :premium_features,
      label: "Enable premium features",
      wrapper_classes: "bg-blue-50 p-3 rounded-lg border border-blue-200",
      label_classes: "text-blue-900 font-medium",
      checkbox_classes: "text-blue-600 focus:ring-blue-500"
    )
  end

  def with_stimulus_data
    render Forms::CheckboxFieldComponent.new(
      form: mock_form_builder,
      field: :tracking_consent,
      label: "Allow analytics tracking",
      help_text: "Help us improve our service by sharing anonymous usage data",
      wrapper_data: {
        controller: "analytics-consent",
        action: "change->analytics-consent#toggle",
        "analytics-consent-target": "checkbox"
      }
    )
  end

  def long_label
    render Forms::CheckboxFieldComponent.new(
      form: mock_form_builder,
      field: :detailed_agreement,
      label: "I understand and agree to the comprehensive terms and conditions, privacy policy, data processing agreement, and all applicable regulations governing the use of this service and the handling of my personal information",
      help_text: "This is a legally binding agreement. Please read all documents carefully before proceeding."
    )
  end

  def custom_field_options
    render Forms::CheckboxFieldComponent.new(
      form: mock_form_builder,
      field: :advanced_settings,
      label: "Enable advanced mode",
      help_text: "Unlocks additional configuration options for power users",
      id: "advanced-mode-toggle",
      "data-testid": "advanced-checkbox",
      "aria-describedby": "advanced-help"
    )
  end

  def multiple_goal_selected
    render Forms::CheckboxFieldComponent.new(
      form: mock_form_builder,
      field: :financial_goals,
      label: "Build emergency fund (3-6 months expenses)",
      value: "emergency_fund",
      multiple: true,
      checked: true,
      help_text: "Recommended as your first financial priority"
    )
  end

  def privacy_consent_styled
    render Forms::CheckboxFieldComponent.new(
      form: mock_form_builder,
      field: :privacy_consent,
      label: "I consent to data processing",
      help_text: "Required for account creation and service provision",
      wrapper_classes: "bg-gray-50 p-3 rounded-lg border",
      label_classes: "text-gray-800 font-medium",
      checkbox_classes: "text-indigo-600 focus:ring-indigo-500"
    )
  end

  def required_with_error
    render Forms::CheckboxFieldComponent.new(
      form: mock_form_with_errors,
      field: :email,
      label: "I accept the terms and conditions (required)",
      help_text: "You must accept our terms to proceed with registration"
    )
  end

  private

  def mock_form_builder
    mock_errors_class = Class.new do
      def key?(field)
        false
      end

      def full_messages_for(field)
        []
      end
    end

    mock_object = OpenStruct.new(errors: mock_errors_class.new)

    mock_form_class = Class.new do
      def initialize(object)
        @object = object
      end

      attr_reader :object

      def check_box(field, options = {}, checked_value = "1", unchecked_value = "0")
        field_name = field.to_s
        field_id = "#{field_name}_#{checked_value}" if options[:multiple]
        field_id ||= field_name

        checked_attr = options[:checked] ? 'checked="checked"' : ''
        multiple_attr = options[:multiple] ? 'multiple="multiple"' : ''
        value_attr = checked_value != "1" ? "value=\"#{checked_value}\"" : ''
        class_attr = options[:class] ? "class=\"#{options[:class]}\"" : ''
        id_attr = "id=\"#{field_id}\""
        name_attr = options[:multiple] ? "name=\"#{field_name}[]\"" : "name=\"#{field_name}\""

        extra_attrs = options.except(:class, :checked, :multiple).map do |key, value|
          next if [:class, :checked, :multiple].include?(key)
          "#{key.to_s.gsub('_', '-')}=\"#{value}\""
        end.compact.join(' ')

        attrs = [id_attr, name_attr, class_attr, checked_attr, multiple_attr, value_attr, extra_attrs].reject(&:empty?).join(' ')

        "<input type=\"checkbox\" #{attrs} />".html_safe
      end

      def label(field, text = nil, options = {})
        field_id = field.to_s
        class_attr = options[:class] ? "class=\"#{options[:class]}\"" : ''
        label_text = text || field.to_s.humanize

        "<label for=\"#{field_id}\" #{class_attr}>#{label_text}</label>".html_safe
      end
    end

    mock_form_class.new(mock_object)
  end

  def mock_form_with_errors
    mock_errors_class = Class.new do
      def key?(field)
        field == :email
      end

      def full_messages_for(field)
        field == :email ? ["Email can't be blank", "Email must be valid"] : []
      end
    end

    mock_object = OpenStruct.new(errors: mock_errors_class.new)

    mock_form_class = Class.new do
      def initialize(object)
        @object = object
      end

      attr_reader :object

      def check_box(field, options = {}, checked_value = "1", unchecked_value = "0")
        field_name = field.to_s
        field_id = "#{field_name}_#{checked_value}" if options[:multiple]
        field_id ||= field_name

        checked_attr = options[:checked] ? 'checked="checked"' : ''
        multiple_attr = options[:multiple] ? 'multiple="multiple"' : ''
        value_attr = checked_value != "1" ? "value=\"#{checked_value}\"" : ''
        class_attr = options[:class] ? "class=\"#{options[:class]}\"" : ''
        id_attr = "id=\"#{field_id}\""
        name_attr = options[:multiple] ? "name=\"#{field_name}[]\"" : "name=\"#{field_name}\""

        extra_attrs = options.except(:class, :checked, :multiple).map do |key, value|
          next if [:class, :checked, :multiple].include?(key)
          "#{key.to_s.gsub('_', '-')}=\"#{value}\""
        end.compact.join(' ')

        attrs = [id_attr, name_attr, class_attr, checked_attr, multiple_attr, value_attr, extra_attrs].reject(&:empty?).join(' ')

        "<input type=\"checkbox\" #{attrs} />".html_safe
      end

      def label(field, text = nil, options = {})
        field_id = field.to_s
        class_attr = options[:class] ? "class=\"#{options[:class]}\"" : ''
        label_text = text || field.to_s.humanize

        "<label for=\"#{field_id}\" #{class_attr}>#{label_text}</label>".html_safe
      end
    end

    mock_form_class.new(mock_object)
  end
end
