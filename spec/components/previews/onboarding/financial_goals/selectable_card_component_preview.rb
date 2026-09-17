# frozen_string_literal: true

# http://localhost:3002/rails/view_components/onboarding/financial_goals/selectable_card_component
class Onboarding::FinancialGoals::SelectableCardComponentPreview < ViewComponent::Preview
  include ActionView::Helpers::FormHelper
  include ActionView::Context

  def default
    render_with_template locals: { goal: sample_goal, space: build_space }
  end

  def selected_state
    render_with_template locals: { goal: sample_goal, space: build_space("pay_off_debt") }
  end

  def unselected_state
    render_with_template locals: { goal: sample_goal, space: build_space }
  end

  def short_description
    goal = create_goal_hash(key: "save_regularly", name: "Save regularly", description: "Put money aside")

    render_with_template locals: { goal: goal, space: build_space }
  end

  def long_description
    goal = create_goal_hash(
      key: "comprehensive_planning",
      name: "Comprehensive Financial Planning",
      description: "Create a detailed financial plan that includes budgeting, investment strategies, retirement planning, insurance coverage, and estate planning to ensure long-term financial security and peace of mind for you and your family"
    )

    render_with_template locals: { goal: goal, space: build_space }
  end

  # Every goal the app offers, with its real translated copy.
  def all_goal_types
    space = build_space
    goals = Onboarding::FinancialGoalForm.new(space).available_goals

    render_with_template locals: { goals: goals, space: space }
  end

  def mixed_selection_states
    goals = [
      { key: "save_regularly", name: "Save regularly", description: "Put money aside every month" },
      { key: "pay_off_debt", name: "Pay off debt", description: "Eliminate existing debts" },
      { key: "track_spending", name: "Track spending", description: "Understand where the money goes" },
      { key: "track_all_accounts", name: "Track all accounts", description: "One view of every balance" }
    ]

    render_with_template locals: { goals: goals, space: build_space("save_regularly", "track_all_accounts") }
  end

  def interactive_example
    goals = [
      { key: "save_regularly", name: "Save regularly", description: "Put money aside every month" },
      { key: "pay_off_debt", name: "Pay off debt", description: "Eliminate existing debts" },
      { key: "track_spending", name: "Track spending", description: "Understand where the money goes" },
      { key: "track_all_accounts", name: "Track all accounts", description: "One view of every balance" }
    ]

    render_with_template locals: { goals: goals, space: build_space }
  end

  def checkbox_visibility_demo
    goals = [
      { key: "unselected_goal", name: "Unselected Goal", description: "Checkbox should be hidden" },
      { key: "selected_goal", name: "Pre-selected Goal", description: "Checkbox should be visible" }
    ]

    render_with_template locals: { goals: goals, space: build_space("selected_goal") }
  end

  def edge_cases
    goals = [
      { key: "empty_desc", name: "No Description Goal", description: "" },
      { key: "long_name", name: "This is a Very Long Goal Name That Might Wrap to Multiple Lines", description: "Short description" },
      { key: "special_chars", name: "Special & Characters", description: "Description with \"quotes\" and <tags> & symbols" },
      { key: "unicode", name: "💰 Wealth Building 🏠", description: "Unicode characters and emojis 📈 📊" },
      { key: "minimal", name: "Min", description: "x" },
      { key: "very_long_desc", name: "Long Description Test", description: "This is an extremely long description that tests how the component handles text wrapping, spacing, and layout when dealing with verbose content that spans multiple lines and might affect the overall card layout and visual hierarchy." }
    ]

    render_with_template locals: { goals: goals, space: build_space("special_chars", "unicode"), columns: 3 }
  end

  private

  # Goals now live on the space; previews run with no database rows.
  def build_space(*selected_goals)
    Space.new(name: "Preview", currency: "XOF", financial_goals: selected_goals)
  end

  def sample_goal
    create_goal_hash(key: "pay_off_debt", name: "Pay off debt", description: "Eliminate existing debts and become debt-free")
  end

  def create_goal_hash(key:, name:, description:)
    ActiveSupport::HashWithIndifferentAccess.new(key: key, name: name, description: description)
  end
end
