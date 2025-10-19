# frozen_string_literal: true

require 'rails_helper'

# Define a test form class outside the describe block
class TestForm < BaseForm
  attribute :name, :string
  attribute :email, :string

  validates :name, presence: true
end

RSpec.describe BaseForm, type: :model do
  let(:form) { TestForm.new }

  describe 'inheritance and inclusions' do
    it 'includes ActiveModel::Model' do
      expect(form.class.ancestors).to include(ActiveModel::Model)
    end

    it 'includes ActiveModel::Attributes' do
      expect(form.class.ancestors).to include(ActiveModel::Attributes)
    end

    it 'includes ActiveModel::Validations' do
      expect(form.class.ancestors).to include(ActiveModel::Validations)
    end
  end

  describe 'ActiveModel behavior' do
    it 'responds to ActiveModel methods' do
      expect(form).to respond_to(:valid?)
      expect(form).to respond_to(:errors)
      expect(form).to respond_to(:persisted?)
    end

    it 'validates attributes' do
      form.name = nil
      expect(form).not_to be_valid
      expect(form.errors[:name]).to include("can't be blank")
    end

    it 'is valid with correct attributes' do
      form.name = 'John Doe'
      expect(form).to be_valid
    end
  end

  describe '#promote_errors' do
    it 'promotes child model errors to the form errors' do
      child_errors = {
        email: ['is invalid'],
        phone: ['is too short']
      }

      form.send(:promote_errors, child_errors)

      expect(form.errors[:email]).to include('is invalid')
      expect(form.errors[:phone]).to include('is too short')
    end

    it 'adds only the first error message for each attribute' do
      child_errors = {
        email: ['is invalid', 'is too long', 'is taken']
      }

      form.send(:promote_errors, child_errors)

      expect(form.errors[:email].count).to eq(1)
      expect(form.errors[:email]).to include('is invalid')
    end

    it 'handles empty error hash' do
      form.send(:promote_errors, {})

      expect(form.errors).to be_empty
    end

    it 'handles multiple attributes with errors' do
      child_errors = {
        name: ['is required'],
        email: ['is invalid'],
        phone: ['is too short'],
        address: ['is blank']
      }

      form.send(:promote_errors, child_errors)

      expect(form.errors[:name]).to include('is required')
      expect(form.errors[:email]).to include('is invalid')
      expect(form.errors[:phone]).to include('is too short')
      expect(form.errors[:address]).to include('is blank')
    end
  end

  describe '#add_custom_error' do
    it 'adds a custom error to the specified attribute' do
      form.send(:add_custom_error, :email, 'must be a company email')

      expect(form.errors[:email]).to include('must be a company email')
    end

    it 'can add multiple custom errors to the same attribute' do
      form.send(:add_custom_error, :email, 'must be a company email')
      form.send(:add_custom_error, :email, 'is already taken')

      expect(form.errors[:email]).to include('must be a company email')
      expect(form.errors[:email]).to include('is already taken')
      expect(form.errors[:email].count).to eq(2)
    end

    it 'can add custom errors to different attributes' do
      form.send(:add_custom_error, :email, 'is invalid')
      form.send(:add_custom_error, :name, 'is too short')

      expect(form.errors[:email]).to include('is invalid')
      expect(form.errors[:name]).to include('is too short')
    end

    it 'works with symbol attributes' do
      form.send(:add_custom_error, :custom_field, 'has an error')

      expect(form.errors[:custom_field]).to include('has an error')
    end
  end

  describe 'integration of promote_errors and add_custom_error' do
    it 'can use both methods together' do
      child_errors = {
        email: ['is invalid']
      }

      form.send(:promote_errors, child_errors)
      form.send(:add_custom_error, :phone, 'is required')

      expect(form.errors[:email]).to include('is invalid')
      expect(form.errors[:phone]).to include('is required')
    end

    it 'maintains form validation errors alongside promoted errors' do
      form.name = nil
      form.valid?

      form.send(:add_custom_error, :email, 'custom error')

      expect(form.errors[:name]).to include("can't be blank")
      expect(form.errors[:email]).to include('custom error')
    end
  end
end
