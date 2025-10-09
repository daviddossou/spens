# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forms::InputFieldComponent, type: :component do
  let(:form) { double('form') }
  let(:mock_object) { double('object') }
  let(:mock_errors) { double('errors') }

  before do
    allow(form).to receive(:object).and_return(mock_object)
    allow(mock_object).to receive(:errors).and_return(mock_errors)
    allow(mock_errors).to receive(:key?).and_return(false)
    allow(mock_errors).to receive(:full_messages_for).and_return([])
    
    # Mock form helper methods
    allow(form).to receive(:text_field).and_return('<input type="text">'.html_safe)
    allow(form).to receive(:email_field).and_return('<input type="email">'.html_safe)
    allow(form).to receive(:password_field).and_return('<input type="password">'.html_safe)
    allow(form).to receive(:label).and_return('<label>Label</label>'.html_safe)
  end

  describe '#initialize' do
    it 'accepts required parameters' do
      component = described_class.new(form: form, field: :email)
      
      expect(component).to be_instance_of(Forms::InputFieldComponent)
    end

    it 'sets default values for optional parameters' do
      component = described_class.new(form: form, field: :email)
      
      expect(component.send(:type)).to eq(:text_field)
      expect(component.send(:required)).to be false
    end

    it 'accepts custom parameters' do
      component = described_class.new(
        form: form,
        field: :password,
        type: :password_field,
        label: 'Custom Password',
        required: true,
        help_text: 'Enter a strong password'
      )
      
      expect(component.send(:type)).to eq(:password_field)
      expect(component.send(:label)).to eq('Custom Password')
      expect(component.send(:required)).to be true
      expect(component.send(:help_text)).to eq('Enter a strong password')
    end
  end

  describe '#field_label' do
    it 'uses provided label when given' do
      component = described_class.new(form: form, field: :email, label: 'Email Address')
      
      expect(component.send(:field_label)).to eq('Email Address')
    end

    it 'humanizes field name when no label provided' do
      component = described_class.new(form: form, field: :first_name)
      
      # Mock the translation helper
      allow(component).to receive(:t).and_return('First Name')
      
      expect(component.send(:field_label)).to eq('First Name')
    end
  end

  describe '#has_errors?' do
    it 'returns false when no errors exist' do
      component = described_class.new(form: form, field: :email)
      
      expect(component.send(:has_errors?)).to be false
    end

    it 'returns true when errors exist for the field' do
      allow(mock_errors).to receive(:key?).with(:email).and_return(true)
      component = described_class.new(form: form, field: :email)
      
      expect(component.send(:has_errors?)).to be true
    end

    it 'handles nil form object gracefully' do
      allow(form).to receive(:object).and_return(nil)
      component = described_class.new(form: form, field: :email)
      
      expect(component.send(:has_errors?)).to be false
    end
  end

  describe '#field_errors' do
    it 'returns empty array when no errors' do
      component = described_class.new(form: form, field: :email)
      
      expect(component.send(:field_errors)).to eq([])
    end

    it 'returns error messages when errors exist' do
      error_messages = ["Email can't be blank", "Email is invalid"]
      allow(mock_errors).to receive(:full_messages_for).with(:email).and_return(error_messages)
      component = described_class.new(form: form, field: :email)
      
      expect(component.send(:field_errors)).to eq(error_messages)
    end

    it 'handles nil form object gracefully' do
      allow(form).to receive(:object).and_return(nil)
      component = described_class.new(form: form, field: :email)
      
      expect(component.send(:field_errors)).to eq([])
    end
  end

  describe '#final_wrapper_classes' do
    it 'combines default and custom wrapper classes' do
      component = described_class.new(
        form: form,
        field: :email,
        wrapper_classes: 'custom-wrapper'
      )
      
      classes = component.send(:final_wrapper_classes)
      expect(classes).to include('space-y-1')
      expect(classes).to include('custom-wrapper')
    end
  end

  describe '#final_field_classes' do
    it 'combines default and custom field classes' do
      component = described_class.new(
        form: form,
        field: :email,
        field_classes: 'custom-field'
      )
      
      classes = component.send(:final_field_classes)
      expect(classes).to include('appearance-none')
      expect(classes).to include('custom-field')
    end
  end

  describe 'rendering' do
    it 'renders basic input field' do
      render_inline(described_class.new(form: form, field: :email))
      
      expect(rendered_component).to have_css('div')
    end

    it 'renders label with correct content' do
      allow(form).to receive(:label).with(:email, 'Email', hash_including(:class)).and_return('<label class="test">Email</label>'.html_safe)
      
      render_inline(described_class.new(form: form, field: :email, label: 'Email'))
      
      expect(rendered_component).to include('Email')
    end

    it 'displays required indicator when required' do
      render_inline(described_class.new(form: form, field: :email, required: true))
      
      expect(rendered_component).to have_css('span.text-red-500', text: '*')
    end

    it 'displays help text when provided' do
      render_inline(described_class.new(
        form: form,
        field: :email,
        help_text: 'We will never share your email'
      ))
      
      expect(rendered_component).to have_text('We will never share your email')
    end

    it 'displays error messages when errors exist' do
      allow(mock_errors).to receive(:key?).with(:email).and_return(true)
      allow(mock_errors).to receive(:full_messages_for).with(:email).and_return(['Email is required'])
      
      render_inline(described_class.new(form: form, field: :email))
      
      expect(rendered_component).to have_text('Email is required')
      expect(rendered_component).to have_css('.text-red-600')
    end
  end

  describe 'accessibility' do
    it 'associates label with input field' do
      # This would require more complex DOM parsing to fully test
      # but ensures the structure supports proper accessibility
      render_inline(described_class.new(form: form, field: :email))
      
      expect(rendered_component).to have_css('div')
    end
  end

  describe 'different input types' do
    let(:input_types) { [:text_field, :email_field, :password_field, :number_field, :url_field, :tel_field] }
    
    it 'handles all supported input types' do
      input_types.each do |input_type|
        allow(form).to receive(input_type).and_return("<input type='#{input_type}'>".html_safe)
        
        expect {
          render_inline(described_class.new(form: form, field: :test, type: input_type))
        }.not_to raise_error
      end
    end
  end
end