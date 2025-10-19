# frozen_string_literal: true

# Shared examples and helpers for controller concern specs

RSpec.shared_context 'controller concern setup' do
  # Setup common to all controller concern tests

  before do
    # Ensure clean state for each test
    I18n.locale = I18n.default_locale if defined?(I18n)
  end

  after do
    # Cleanup after each test
    I18n.locale = I18n.default_locale if defined?(I18n)
  end
end

RSpec.shared_examples 'a controller concern' do |concern_module|
  it "can be included in a controller" do
    test_controller_class = Class.new(ApplicationController) do
      include concern_module
    end

    expect(test_controller_class.included_modules).to include(concern_module)
  end

  it "extends ActiveSupport::Concern" do
    expect(concern_module.ancestors).to include(ActiveSupport::Concern)
  end
end

# Shared examples for concerns that add before_actions
RSpec.shared_examples 'a concern with before_actions' do |concern_module, expected_callbacks = []|
  let(:controller_class) do
    Class.new(ApplicationController) do
      include concern_module
    end
  end

  expected_callbacks.each do |callback_name|
    it "adds #{callback_name} before_action" do
      callback_exists = controller_class._process_action_callbacks.any? do |callback|
        callback.filter == callback_name
      end

      expect(callback_exists).to be true
    end
  end
end

# Helper methods for controller concern testing
module ControllerConcernTestHelpers
  def mock_controller_methods(controller, methods = {})
    methods.each do |method_name, return_value|
      allow(controller).to receive(method_name).and_return(return_value)
    end
  end

  def mock_request_env(request, env_vars = {})
    env_vars.each do |key, value|
      request.env[key] = value
    end
  end

  def create_test_controller_with_concern(concern_module, &block)
    controller_class = Class.new(ApplicationController) do
      include concern_module

      # Add test action
      def index
        render plain: 'test_response'
      end

      # Allow custom methods to be added
      class_eval(&block) if block_given?
    end

    controller_class.new
  end

  def expect_redirect_behavior(controller, action, expected_path, params = {})
    if params.any?
      send(action, :index, params: params)
    else
      send(action, :index)
    end

    expect(response).to redirect_to(expected_path)
  end

  def expect_successful_response(controller, action, params = {})
    if params.any?
      send(action, :index, params: params)
    else
      send(action, :index)
    end

    expect(response).to have_http_status(:success)
  end
end

RSpec.configure do |config|
  config.include ControllerConcernTestHelpers, type: :controller
  config.include_context 'controller concern setup', type: :controller
end
