# frozen_string_literal: true

class Onboarding::ProfileSetups::SelectFieldComponent < Forms::SelectFieldComponent
  def initialize(form:, field:, **options)
    label = I18n.t("onboarding.profile_setups.select_field_component.#{field}_label", default: field.to_s.humanize)
    help_text = I18n.t("onboarding.profile_setups.select_field_component.#{field}_help", default: nil)

    super(
      form: form,
      field: field,
      options: options_for(field),
      priority_options: Onboarding::OptionsService.priority_options_for(field),
      searchable: Onboarding::OptionsService.searchable?(field),
      label: label,
      help_text: help_text,
      **options
    )
  end

  private

  def options_for(field)
    Onboarding::OptionsService.options_for(field)
  end

  def priority_options_for(field)
    Onboarding::OptionsService.priority_options_for(field)
  end

  def searchable?(field)
    Onboarding::OptionsService.searchable?(field)
  end
end
