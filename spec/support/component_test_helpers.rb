# frozen_string_literal: true

# Shared helpers for ViewComponent specs
module ComponentTestHelpers
  # Creates a real Rails form builder for testing
  def form_builder_for(model: nil, with_errors: false)
    model ||= User.new

    if with_errors
      model.email = "" if model.respond_to?(:email=)
      model.valid?
    end

    action_view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    ActionView::Helpers::FormBuilder.new(:user, model, action_view, {})
  end

  # For backward compatibility, accepts model as first argument or keyword
  def mock_form_builder(model = nil, with_errors: false)
    form_builder_for(model: model, with_errors: with_errors)
  end

  def mock_form_with_errors
    form_builder_for(with_errors: true)
  end
end

RSpec.configure do |config|
  config.include ComponentTestHelpers, type: :component
end
