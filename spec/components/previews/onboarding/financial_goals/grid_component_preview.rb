# frozen_string_literal: true

class Onboarding::FinancialGoals::GridComponentPreview < ViewComponent::Preview
  include ActionView::Helpers::FormHelper
  include ActionView::Context

  def default
    user = User.new(financial_goals: [ 'save_for_emergency' ])
    form_object = Onboarding::FinancialGoalForm.new(user)

    render_with_template locals: {
      form_object: form_object
    }
  end

  def none_selected
    user = User.new(financial_goals: [])
    form_object = Onboarding::FinancialGoalForm.new(user)

    render_with_template locals: {
      form_object: form_object
    }
  end

  def all_selected
    user = User.new(financial_goals: User::FINANCIAL_GOALS)
    form_object = Onboarding::FinancialGoalForm.new(user)

    render_with_template locals: {
      form_object: form_object
    }
  end
end
