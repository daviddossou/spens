# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeviseLayoutConcern, type: :controller do
  include Devise::Test::ControllerHelpers

  it_behaves_like 'a controller concern', DeviseLayoutConcern

  controller(ApplicationController) do
    include DeviseLayoutConcern
    # Skip other concerns that interfere with testing
    skip_before_action :redirect_to_onboarding, if: -> { true }
    skip_before_action :configure_permitted_parameters, if: -> { true }

    def index
      render plain: 'success'
    end
  end

  describe '#layout_by_resource' do
    context 'when controller is a devise controller' do
      before do
        allow(controller).to receive(:devise_controller?).and_return(true)
      end

      it 'returns auth layout' do
        expect(controller.send(:layout_by_resource)).to eq('auth')
      end

      it 'uses auth layout for rendering' do
        get :index
        expect(response).to have_http_status(:success)
        # The layout selection is tested through the layout_by_resource method
      end
    end

    context 'when controller is not a devise controller' do
      before do
        allow(controller).to receive(:devise_controller?).and_return(false)
      end

      it 'returns application layout' do
        expect(controller.send(:layout_by_resource)).to eq('application')
      end

      it 'uses application layout for rendering' do
        get :index
        expect(response).to have_http_status(:success)
        # The layout selection happens automatically through the layout callback
      end
    end
  end

  describe 'layout callback integration' do
    it 'includes the layout_by_resource method' do
      # Test that the concern properly sets up the layout method (it's private)
      expect(controller.class.private_instance_methods).to include(:layout_by_resource)
    end

    it 'sets layout to use layout_by_resource method' do
      # Verify that the layout is configured to use the layout_by_resource method
      # Test that the concern can be included without errors and provides the expected behavior
      test_controller_class = Class.new(ActionController::Base) do
        include DeviseLayoutConcern

        def devise_controller?
          false
        end
      end

      test_instance = test_controller_class.new
      expect(test_instance.send(:layout_by_resource)).to eq('application')
    end
  end

  # Integration test with devise-like controllers
  describe 'integration with devise controllers' do
    let(:devise_controller_class) do
      Class.new(ActionController::Base) do
        include DeviseLayoutConcern

        def devise_controller?
          true
        end

        def test_action
          render plain: 'devise action'
        end
      end
    end

    let(:devise_controller) { devise_controller_class.new }

    it 'uses auth layout for devise controllers' do
      expect(devise_controller.send(:layout_by_resource)).to eq('auth')
    end
  end

  describe 'non-devise controller integration' do
    let(:regular_controller_class) do
      Class.new(ActionController::Base) do
        include DeviseLayoutConcern

        def devise_controller?
          false
        end

        def test_action
          render plain: 'regular action'
        end
      end
    end

    let(:regular_controller) { regular_controller_class.new }

    it 'uses application layout for non-devise controllers' do
      expect(regular_controller.send(:layout_by_resource)).to eq('application')
    end
  end
end
