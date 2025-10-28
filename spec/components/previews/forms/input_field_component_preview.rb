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
      field_types: [ :text_field, :email_field, :password_field, :number_field, :url_field, :telephone_field ]
    }
  end

  # Autocomplete with Account templates
  def autocomplete_account_templates
    # Get account template suggestions from i18n
    account_suggestions = I18n.t('account_templates').values

    render_with_template locals: {
      suggestions: account_suggestions,
      allow_create: true,
      model_name: "Account"
    }
  end

  # Autocomplete with TransactionType expense templates
  def autocomplete_expense_types
    # Get expense transaction type templates
    expense_types = I18n.t('transaction_type_templates')
      .select { |_, attrs| attrs[:kind] == 'expense' }
      .map { |_, attrs| attrs[:name] }

    render_with_template locals: {
      suggestions: expense_types,
      allow_create: true,
      model_name: "TransactionType (Expense)"
    }
  end

  # Autocomplete with TransactionType income templates
  def autocomplete_income_types
    # Get income transaction type templates
    income_types = I18n.t('transaction_type_templates')
      .select { |_, attrs| attrs[:kind] == 'income' }
      .map { |_, attrs| attrs[:name] }

    render_with_template locals: {
      suggestions: income_types,
      allow_create: true,
      model_name: "TransactionType (Income)"
    }
  end

  # Autocomplete with TransactionType all templates (mixed kinds)
  def autocomplete_all_transaction_types
    # Get all transaction type templates with kind labels
    all_types = I18n.t('transaction_type_templates').map do |key, attrs|
      "#{attrs[:name]} (#{attrs[:kind]})"
    end

    render_with_template locals: {
      suggestions: all_types,
      allow_create: false,
      model_name: "TransactionType (All)"
    }
  end

  # Field with prepend addon (currency)
  def with_prepend_addon
    render_with_template
  end

  # Field with append addon (percentage)
  def with_append_addon
    render_with_template
  end

  # Field with both prepend and append addons
  def with_both_addons
    render_with_template
  end

  # Disabled field
  def disabled_field
    render_with_template
  end

  # Field with placeholder
  def with_placeholder
    render_with_template
  end

  # Number field with step and min/max
  def number_field_with_options
    render_with_template
  end
end
