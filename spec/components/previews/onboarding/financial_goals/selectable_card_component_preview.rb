# frozen_string_literal: true

class Onboarding::FinancialGoals::SelectableCardComponentPreview < ViewComponent::Preview
  include ActionView::Helpers::FormHelper
  include ActionView::Context

  def default
    render_with_template locals: {
      goal: sample_goal,
      user: User.new
    }
  end

  def selected_state
    user = User.new
    user.financial_goals = ['build_wealth']
    render_with_template locals: {
      goal: sample_goal,
      user: user
    }
  end

  def unselected_state
    render_with_template locals: {
      goal: sample_goal,
      user: User.new
    }
  end

  def short_description
    goal = create_goal_hash(
      key: 'save_emergency',
      name: 'Emergency Fund',
      description: 'Save for emergencies'
    )

    render_with_template locals: {
      goal: goal,
      user: User.new
    }
  end

  def long_description
    goal = create_goal_hash(
      key: 'comprehensive_planning',
      name: 'Comprehensive Financial Planning',
      description: 'Create a detailed financial plan that includes budgeting, investment strategies, retirement planning, insurance coverage, and estate planning to ensure long-term financial security and peace of mind for you and your family'
    )

    render_with_template locals: {
      goal: goal,
      user: User.new
    }
  end

  def all_goal_types
    goals_data = [
      { key: 'save_for_emergency', name: 'Build Emergency Fund', description: 'Save money for unexpected expenses and emergencies' },
      { key: 'pay_off_debt', name: 'Pay Off Debt', description: 'Eliminate existing debts and become debt-free' },
      { key: 'save_for_house', name: 'Save for House', description: 'Build funds for a home down payment or purchase' },
      { key: 'save_for_retirement', name: 'Save for Retirement', description: 'Plan and save for your golden years' },
      { key: 'build_wealth', name: 'Build Wealth', description: 'Grow your net worth through investments and savings' },
      { key: 'track_spending', name: 'Track Spending', description: 'Monitor and understand your spending habits' }
    ]

    goals = goals_data.map do |goal_data|
      create_goal_hash(
        key: goal_data[:key],
        name: goal_data[:name],
        description: goal_data[:description]
      )
    end

    render_with_template locals: {
      goals: goals,
      user: User.new
    }
  end

  def mixed_selection_states
    goals = [
      { key: 'save_for_emergency', name: 'Build Emergency Fund', description: 'Save money for unexpected expenses' },
      { key: 'pay_off_debt', name: 'Pay Off Debt', description: 'Eliminate existing debts' },
      { key: 'save_for_house', name: 'Save for House', description: 'Build funds for home purchase' },
      { key: 'build_wealth', name: 'Build Wealth', description: 'Grow your net worth' }
    ]

    user = User.new
    user.financial_goals = ['save_for_emergency', 'build_wealth']

    render_with_template locals: {
      goals: goals,
      user: user
    }
  end

  def interactive_example
    goals = [
      { key: 'save_for_emergency', name: 'Build Emergency Fund', description: 'Save money for unexpected expenses' },
      { key: 'pay_off_debt', name: 'Pay Off Debt', description: 'Eliminate existing debts' },
      { key: 'save_for_house', name: 'Save for House', description: 'Build funds for home purchase' },
      { key: 'build_wealth', name: 'Build Wealth', description: 'Grow your net worth' }
    ]

    render_with_template locals: {
      goals: goals,
      user: User.new
    }
  end

  def checkbox_visibility_demo
    goals = [
      { key: 'unselected_goal', name: 'Unselected Goal', description: 'Checkbox should be hidden' },
      { key: 'selected_goal', name: 'Pre-selected Goal', description: 'Checkbox should be visible' }
    ]

    user = User.new
    user.financial_goals = ['selected_goal']

    render_with_template locals: {
      goals: goals,
      user: user
    }
  end

  def edge_cases
    goals = [
      { key: 'empty_desc', name: 'No Description Goal', description: '' },
      { key: 'long_name', name: 'This is a Very Long Goal Name That Might Wrap to Multiple Lines', description: 'Short description' },
      { key: 'special_chars', name: 'Special & Characters', description: 'Description with "quotes" and <tags> & symbols' },
      { key: 'unicode', name: '💰 Wealth Building 🏠', description: 'Unicode characters and emojis 📈 📊' },
      { key: 'minimal', name: 'Min', description: 'x' },
      { key: 'very_long_desc', name: 'Long Description Test', description: 'This is an extremely long description that tests how the component handles text wrapping, spacing, and layout when dealing with verbose content that spans multiple lines and might affect the overall card layout and visual hierarchy.' }
    ]

    user = User.new
    user.financial_goals = ['special_chars', 'unicode']

    render_with_template locals: {
      goals: goals,
      user: user,
      columns: 3
    }
  end

  private

  def sample_goal
    create_goal_hash(
      key: 'build_wealth',
      name: 'Build Wealth',
      description: 'Grow your net worth through investments and savings'
    )
  end

  def create_goal_hash(key:, name:, description:)
    ActiveSupport::HashWithIndifferentAccess.new({
      key: key,
      name: name,
      description: description
    })
  end
end
