# frozen_string_literal: true

class Onboarding::ProfileSetups::SelectFieldComponentPreview < ViewComponent::Preview
  include ActionView::Helpers::FormHelper
  include ActionView::Context

  # Country field - searchable with priority options
  # @label Country Select
  def country_field
    render_with_template locals: {}
  end

  # Currency field - searchable with priority options
  # @label Currency Select
  def currency_field
    render_with_template locals: {}
  end

  # Income frequency field - not searchable
  # @label Income Frequency Select
  def income_frequency_field
    render_with_template locals: {}
  end

  # Main income source field - not searchable
  # @label Main Income Source Select
  def main_income_source_field
    render_with_template locals: {}
  end

  # With pre-selected value
  # @label Pre-selected Value
  def with_selected_value
    render_with_template locals: {}
  end

  # With validation error
  # @label With Error
  def with_error
    render_with_template locals: {}
  end

  # All fields together
  # @label Complete Form
  def complete_form
    render_with_template locals: {}
  end
end
