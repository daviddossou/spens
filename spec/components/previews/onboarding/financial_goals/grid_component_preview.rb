# frozen_string_literal: true

# http://localhost:3002/rails/view_components/onboarding/financial_goals/grid_component
class Onboarding::FinancialGoals::GridComponentPreview < ViewComponent::Preview
  include ActionView::Helpers::FormHelper
  include ActionView::Context

  def default
    render_with_template locals: { form_object: build_form([ "save_regularly" ]) }
  end

  def none_selected
    render_with_template locals: { form_object: build_form([]) }
  end

  def all_selected
    render_with_template locals: { form_object: build_form(Space::FINANCIAL_GOALS) }
  end

  private

  # Goals now live on the space; previews run with no database rows.
  def build_form(financial_goals)
    space = Space.new(name: "Preview", currency: "XOF", financial_goals: financial_goals)
    Onboarding::FinancialGoalForm.new(space)
  end
end
