# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::ProfileSetups::SelectFieldComponent, type: :component do
  let(:form) { mock_form_builder }

  describe 'country field' do
    it 'renders country select with searchable option' do
      rendered = render_inline(described_class.new(form: form, field: :country))

      expect(rendered.to_html).to include('data-controller="searchable-select"')
      expect(rendered.css('select').first['name']).to include('[country]')
      expect(rendered.css('select').first['class']).to include('searchable-select')
    end

    it 'includes priority countries with divider' do
      rendered = render_inline(described_class.new(form: form, field: :country))

      # Should have a divider option separating priority from all countries
      expect(rendered.css('option[disabled][class="option-divider"]')).to be_present
    end

    it 'uses i18n label' do
      rendered = render_inline(described_class.new(form: form, field: :country))

      # Should render a label (actual text depends on i18n)
      expect(rendered.css('label')).to be_present
    end
  end

  describe 'currency field' do
    it 'renders currency select with searchable option' do
      rendered = render_inline(described_class.new(form: form, field: :currency))

      expect(rendered.to_html).to include('data-controller="searchable-select"')
      expect(rendered.css('select').first['name']).to include('[currency]')
      expect(rendered.css('select').first['class']).to include('searchable-select')
    end

    it 'includes priority currencies with divider' do
      rendered = render_inline(described_class.new(form: form, field: :currency))

      expect(rendered.css('option[disabled][class="option-divider"]')).to be_present
    end
  end

  describe 'income_frequency field' do
    it 'renders income frequency select without search' do
      rendered = render_inline(described_class.new(form: form, field: :income_frequency))

      # Should not be searchable
      expect(rendered.to_html).not_to include('data-controller="searchable-select"')
      expect(rendered.css('select').first['name']).to include('[income_frequency]')
    end

    it 'does not have priority options divider' do
      rendered = render_inline(described_class.new(form: form, field: :income_frequency))

      # Should not have dividers
      expect(rendered.css('option[disabled][class="option-divider"]')).to be_empty
    end
  end

  describe 'main_income_source field' do
    it 'renders main income source select without search' do
      rendered = render_inline(described_class.new(form: form, field: :main_income_source))

      expect(rendered.to_html).not_to include('data-controller="searchable-select"')
      expect(rendered.css('select').first['name']).to include('[main_income_source]')
    end
  end

  describe 'custom options' do
    it 'shows required indicator in label' do
      rendered = render_inline(described_class.new(
        form: form,
        field: :country,
        required: true
      ))

      expect(rendered.css('.form-label-required')).to be_present
      expect(rendered.to_html).to include('*')
    end

    it 'accepts custom label' do
      rendered = render_inline(described_class.new(
        form: form,
        field: :country,
        label: 'Custom Country Label'
      ))

      expect(rendered.to_html).to include('Custom Country Label')
    end

    it 'accepts custom help text' do
      rendered = render_inline(described_class.new(
        form: form,
        field: :country,
        help_text: 'Custom help text'
      ))

      expect(rendered.to_html).to include('Custom help text')
    end
  end

  describe 'integration with OptionsService' do
    it 'uses OptionsService for country options' do
      expect(Onboarding::OptionsService).to receive(:options_for).with(:country).and_call_original
      expect(Onboarding::OptionsService).to receive(:priority_options_for).with(:country).and_call_original
      expect(Onboarding::OptionsService).to receive(:searchable?).with(:country).and_call_original

      render_inline(described_class.new(form: form, field: :country))
    end

    it 'checks if field is searchable via OptionsService' do
      expect(Onboarding::OptionsService.searchable?(:country)).to be true
      expect(Onboarding::OptionsService.searchable?(:currency)).to be true
      expect(Onboarding::OptionsService.searchable?(:income_frequency)).to be false
    end
  end
end
