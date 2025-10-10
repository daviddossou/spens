# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :controller do
  include Devise::Test::ControllerHelpers

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "controller class" do
    it "inherits from Devise::RegistrationsController" do
      expect(described_class.superclass).to eq(Devise::RegistrationsController)
    end

    it "defines the set_minimum_password_length before_action" do
      expect(described_class._process_action_callbacks.any? { |cb|
        cb.filter == :set_minimum_password_length
      }).to be true
    end
  end

  describe "parameter filtering methods" do
    let(:controller_instance) { described_class.new }

    it "has custom parameter methods defined" do
      expect(controller_instance.private_methods).to include(:sign_up_params)
      expect(controller_instance.private_methods).to include(:account_update_params)
    end
  end

  describe "private methods" do
    let(:controller_instance) { described_class.new }

    describe "#set_minimum_password_length" do
      it "sets minimum password length from User model validators" do
        controller_instance.send(:set_minimum_password_length)
        expect(controller_instance.instance_variable_get(:@minimum_password_length)).to eq(6)
      end

      it "falls back to 6 if no validator found" do
        # Mock the scenario where no length validator exists
        allow(User).to receive(:validators_on).with(:password).and_return([])
        controller_instance.send(:set_minimum_password_length)
        expect(controller_instance.instance_variable_get(:@minimum_password_length)).to eq(6)
      end
    end
  end

  describe "controller behavior" do
    it "responds to devise controller methods" do
      expect(described_class.instance_methods).to include(:new, :create, :edit, :update, :destroy)
    end

    it "has custom before_action callback" do
      callbacks = described_class._process_action_callbacks.map(&:filter)
      expect(callbacks).to include(:set_minimum_password_length)
    end
  end

  describe "error handling" do
    let(:controller_instance) { described_class.new }

    context "when User model validation changes" do
      it "adapts to different minimum password lengths" do
        # Mock a different minimum length
        mock_validator = instance_double('ActiveModel::Validator', kind: :length, options: { minimum: 8 })
        allow(User).to receive(:validators_on).with(:password).and_return([ mock_validator ])

        controller_instance.send(:set_minimum_password_length)
        expect(controller_instance.instance_variable_get(:@minimum_password_length)).to eq(8)
      end
    end

    context "with missing validator" do
      it "handles missing length validator gracefully" do
        allow(User).to receive(:validators_on).with(:password).and_return([])

        expect { controller_instance.send(:set_minimum_password_length) }.not_to raise_error
        expect(controller_instance.instance_variable_get(:@minimum_password_length)).to eq(6)
      end
    end
  end
end
