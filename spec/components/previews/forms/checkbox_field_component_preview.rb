# frozen_string_literal: true

class Forms::CheckboxFieldComponentPreview < ViewComponent::Preview
  include ActionView::Helpers::FormHelper
  include ActionView::Context

  def default
    render_with_template locals: {}
  end

  def custom_label
    render_with_template locals: {}
  end

  def with_help_text
    render_with_template locals: {}
  end

  def with_errors
    user = User.new(email: "")
    user.valid?
    render_with_template locals: { user: user }
  end

  def hidden_label
    render_with_template locals: {}
  end

  def multiple_unchecked
    render_with_template locals: {}
  end

  def multiple_checked
    render_with_template locals: {}
  end

  def custom_styling
    render_with_template locals: {}
  end

  def with_stimulus_data
    render_with_template locals: {}
  end

  def long_label
    render_with_template locals: {}
  end

  def custom_field_options
    render_with_template locals: {}
  end

  def multiple_goal_selected
    render_with_template locals: {}
  end

  def privacy_consent_styled
    render_with_template locals: {}
  end

  def required_with_error
    user = User.new(email: "")
    user.valid?
    render_with_template locals: { user: user }
  end
end
