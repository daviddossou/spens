# frozen_string_literal: true

module Forms
  # @label Form Errors
  class ErrorsComponentPreview < ViewComponent::Preview
    # Compact list, as rendered above most forms
    def default
      render(Forms::ErrorsComponent.new(object: invalid_user))
    end

    # Detailed box with a count heading (sign-up)
    def detailed
      render(Forms::ErrorsComponent.new(object: invalid_user, detailed: true))
    end

    # Nothing renders without errors
    def without_errors
      render(Forms::ErrorsComponent.new(object: User.new))
    end

    private

    def invalid_user
      User.new.tap do |user|
        user.errors.add(:email, :blank)
        user.errors.add(:password, :too_short, count: 8)
      end
    end
  end
end
