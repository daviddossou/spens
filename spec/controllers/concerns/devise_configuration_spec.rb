# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeviseConfiguration, type: :controller do
  include Devise::Test::ControllerHelpers

  it_behaves_like 'a controller concern', DeviseConfiguration
  it_behaves_like 'a concern with before_actions', DeviseConfiguration, [ :configure_permitted_parameters ]

  controller(ApplicationController) do
    include DeviseConfiguration
    # Skip onboarding redirection for these tests
    skip_before_action :redirect_to_onboarding, if: -> { true }

    def index
      render plain: 'success'
    end
  end

  let(:user) { create(:user) }

  describe 'parameter configuration' do
    context 'when controller is a devise controller' do
      before do
        allow(controller).to receive(:devise_controller?).and_return(true)
        allow(controller).to receive(:devise_parameter_sanitizer).and_return(devise_parameter_sanitizer)
      end

      let(:devise_parameter_sanitizer) { instance_double(Devise::ParameterSanitizer) }

      it 'configures permitted parameters for sign_up' do
        expect(devise_parameter_sanitizer).to receive(:permit).with(:sign_up, keys: [ :first_name, :last_name, :phone_number ])
        expect(devise_parameter_sanitizer).to receive(:permit).with(:account_update, keys: [ :first_name, :last_name, :phone_number ])

        controller.send(:configure_permitted_parameters)
      end

      it 'configures permitted parameters for account_update' do
        expect(devise_parameter_sanitizer).to receive(:permit).with(:sign_up, keys: [ :first_name, :last_name, :phone_number ])
        expect(devise_parameter_sanitizer).to receive(:permit).with(:account_update, keys: [ :first_name, :last_name, :phone_number ])

        controller.send(:configure_permitted_parameters)
      end

      it 'calls configure_permitted_parameters before action' do
        expect(controller).to receive(:configure_permitted_parameters)

        get :index
      end
    end

    context 'when controller is not a devise controller' do
      before do
        allow(controller).to receive(:devise_controller?).and_return(false)
      end

      it 'does not configure permitted parameters' do
        expect(controller).not_to receive(:configure_permitted_parameters)

        get :index
      end
    end
  end

  describe '#after_sign_in_path_for' do
    it 'redirects to dashboard path after sign in' do
      path = controller.send(:after_sign_in_path_for, user)
      expect(path).to eq(dashboard_path)
    end

    it 'works with any resource type' do
      path = controller.send(:after_sign_in_path_for, instance_double(User))
      expect(path).to eq(dashboard_path)
    end
  end

  describe '#after_sign_out_path_for' do
    it 'redirects to root path after sign out' do
      path = controller.send(:after_sign_out_path_for, user)
      expect(path).to eq(root_path)
    end

    it 'works with resource scope' do
      path = controller.send(:after_sign_out_path_for, :user)
      expect(path).to eq(root_path)
    end

    it 'works with nil resource' do
      path = controller.send(:after_sign_out_path_for, nil)
      expect(path).to eq(root_path)
    end
  end

  # Integration tests with actual Devise controllers
  describe 'integration with Devise::SessionsController' do
    let(:sessions_controller_class) do
      Class.new(Devise::SessionsController) do
        include DeviseConfiguration

        # Override to avoid routing issues in tests
        def dashboard_path
          '/dashboard'
        end

        def root_path
          '/'
        end
      end
    end

    let(:sessions_controller) { sessions_controller_class.new }

    before do
      allow(sessions_controller).to receive(:request).and_return(ActionDispatch::Request.new({}))
      allow(sessions_controller).to receive(:response).and_return(ActionDispatch::Response.new)
    end

    it 'properly configures redirect paths for Devise sessions controller' do
      expect(sessions_controller.send(:after_sign_in_path_for, user)).to eq('/dashboard')
      expect(sessions_controller.send(:after_sign_out_path_for, user)).to eq('/')
    end
  end

  describe 'integration with Devise::RegistrationsController' do
    let(:registrations_controller_class) do
      Class.new(Devise::RegistrationsController) do
        include DeviseConfiguration

        def dashboard_path
          '/dashboard'
        end

        def root_path
          '/'
        end
      end
    end

    let(:registrations_controller) { registrations_controller_class.new }
    let(:parameter_sanitizer) { Devise::ParameterSanitizer.new(User, :user, {}) }

    before do
      allow(registrations_controller).to receive(:request).and_return(ActionDispatch::Request.new({}))
      allow(registrations_controller).to receive(:response).and_return(ActionDispatch::Response.new)
      allow(registrations_controller).to receive(:devise_parameter_sanitizer).and_return(parameter_sanitizer)
    end

    it 'permits additional parameters for user registration' do
      registrations_controller.send(:configure_permitted_parameters)

      sign_up_keys = parameter_sanitizer.instance_variable_get(:@permitted)[:sign_up] || []
      account_update_keys = parameter_sanitizer.instance_variable_get(:@permitted)[:account_update] || []

      expect(sign_up_keys).to include(:first_name, :last_name, :phone_number)
      expect(account_update_keys).to include(:first_name, :last_name, :phone_number)
    end
  end

  describe 'callback integration' do
    it 'sets up before_action callback for devise controllers' do
      devise_controller_class = Class.new(ApplicationController) do
        include DeviseConfiguration

        def devise_controller?
          true
        end
      end

      expect(devise_controller_class._process_action_callbacks.any? do |callback|
        callback.filter == :configure_permitted_parameters
      end).to be true
    end

    it 'respects the conditional for before_action' do
      non_devise_controller_class = Class.new(ActionController::Base) do
        include DeviseConfiguration

        def devise_controller?
          false
        end

        def index
          render plain: 'success'
        end
      end

      # Test that the before_action callback is conditional
      callback = non_devise_controller_class._process_action_callbacks.find do |cb|
        cb.filter == :configure_permitted_parameters
      end

      expect(callback).to be_present
      # Check that the callback has a conditional (the specific format may vary by Rails version)
      expect(callback.instance_variable_get(:@if)).to include(:devise_controller?)
    end
  end

  describe 'parameter sanitization behavior' do
    let(:devise_controller_class) do
      Class.new(ApplicationController) do
        include DeviseConfiguration

        def devise_controller?
          true
        end
      end
    end

    let(:devise_controller) { devise_controller_class.new }
    let(:sanitizer) { instance_double(Devise::ParameterSanitizer) }

    before do
      allow(devise_controller).to receive(:devise_parameter_sanitizer).and_return(sanitizer)
    end

    it 'permits the correct keys for both sign_up and account_update' do
      expect(sanitizer).to receive(:permit).with(:sign_up, keys: [ :first_name, :last_name, :phone_number ])
      expect(sanitizer).to receive(:permit).with(:account_update, keys: [ :first_name, :last_name, :phone_number ])

      devise_controller.send(:configure_permitted_parameters)
    end

    it 'calls permit method twice for both actions' do
      # The concern should configure both sign_up and account_update
      expect(sanitizer).to receive(:permit).twice

      devise_controller.send(:configure_permitted_parameters)
    end
  end
end
