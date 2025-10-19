# frozen_string_literal: true

class Onboarding::Goals::GoalCardComponentPreview < ViewComponent::Preview
  def default
    render Onboarding::Goals::GoalCardComponent.new(
      item: sample_goal,
      form: mock_form_builder,
      model: mock_model([])
    )
  end

  def selected_state
    render Onboarding::Goals::GoalCardComponent.new(
      item: sample_goal,
      form: mock_form_builder,
      model: mock_model(['build_wealth'])
    )
  end

  def unselected_state
    render Onboarding::Goals::GoalCardComponent.new(
      item: sample_goal,
      form: mock_form_builder,
      model: mock_model([])
    )
  end

  def short_description
    goal = create_goal_hash(
      key: 'save_emergency',
      name: 'Emergency Fund',
      description: 'Save for emergencies'
    )

    render Onboarding::Goals::GoalCardComponent.new(
      item: goal,
      form: mock_form_builder,
      model: mock_model([])
    )
  end

  def long_description
    goal = create_goal_hash(
      key: 'comprehensive_planning',
      name: 'Comprehensive Financial Planning',
      description: 'Create a detailed financial plan that includes budgeting, investment strategies, retirement planning, insurance coverage, and estate planning to ensure long-term financial security and peace of mind for you and your family'
    )

    render Onboarding::Goals::GoalCardComponent.new(
      item: goal,
      form: mock_form_builder,
      model: mock_model([])
    )
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

    # Pre-process goals using our helper methods
    goals = goals_data.map do |goal_data|
      create_goal_hash(
        key: goal_data[:key],
        name: goal_data[:name],
        description: goal_data[:description]
      )
    end

    render_with_template locals: {
      goals: goals,
      mock_form: mock_form_builder,
      mock_model: mock_model([])
    }
  end

  def mixed_selection_states
    goals = [
      { key: 'save_for_emergency', name: 'Build Emergency Fund', description: 'Save money for unexpected expenses' },
      { key: 'pay_off_debt', name: 'Pay Off Debt', description: 'Eliminate existing debts' },
      { key: 'save_for_house', name: 'Save for House', description: 'Build funds for home purchase' },
      { key: 'build_wealth', name: 'Build Wealth', description: 'Grow your net worth' }
    ]

    # Select some goals to show mixed states (pre-selected for demonstration)
    selected_goals = ['save_for_emergency', 'build_wealth']

    render_with_template locals: {
      goals: goals,
      mock_form: mock_form_builder,
      mock_model: mock_model(selected_goals)
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
      mock_form: mock_form_builder,
      mock_model: mock_model([])
    }
  end

  def checkbox_visibility_demo
    goals = [
      { key: 'unselected_goal', name: 'Unselected Goal', description: 'Checkbox should be hidden' },
      { key: 'selected_goal', name: 'Pre-selected Goal', description: 'Checkbox should be visible' }
    ]

    render_with_template locals: {
      goals: goals,
      mock_form: mock_form_builder,
      mock_model: mock_model(['selected_goal'])
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

    render_with_template locals: {
      goals: goals,
      mock_form: mock_form_builder,
      mock_model: mock_model(['special_chars', 'unicode']),
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
    # Use HashWithIndifferentAccess to support both string and symbol keys
    # This ensures the component can access both goal[:key] and goal['key']
    ActiveSupport::HashWithIndifferentAccess.new({
      key: key,
      name: name,
      description: description
    })
  end



  def mock_form_builder
    # Create a simple but functional mock form builder
    form_object = OpenStruct.new(financial_goals: [])

    # Create a mock that responds to the methods the component needs
    mock_builder = OpenStruct.new(
      object: form_object,
      object_name: 'onboarding_financial_goal_form'
    )

    # Add the check_box method that Forms::CheckboxFieldComponent needs
    # Rails form builder signature: check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    def mock_builder.check_box(field, options = {}, checked_value = "1", unchecked_value = "0")
      value = options[:value] || checked_value
      checked = options[:checked] ? 'checked="checked"' : ''
      multiple = options[:multiple] ? '[]' : ''
      name = "#{object_name}[#{field}]#{multiple}"

      # Safely convert value to string and handle parameterization
      safe_value = value.to_s
      safe_id_value = safe_value.gsub(/[^a-zA-Z0-9_-]/, '_').downcase
      id = "#{object_name}_#{field}_#{safe_id_value}"

      %(<input type="checkbox" value="#{safe_value}" name="#{name}" id="#{id}" #{checked} />).html_safe
    end

    mock_builder
  end

  def mock_model(selected_goals = [])
    # Create a model object that behaves like the real form model
    mock = OpenStruct.new(financial_goals: selected_goals)

    # Add errors object if needed
    def mock.errors
      @errors ||= OpenStruct.new(
        full_messages: [],
        empty?: true,
        any?: false
      )
    end

    mock
  end
end
