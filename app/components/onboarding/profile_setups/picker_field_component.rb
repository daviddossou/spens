# frozen_string_literal: true

# One onboarding question answered by a tap: the shared picker layer lists the
# choices, the usual ones first, so no keyboard opens on a phone.
class Onboarding::ProfileSetups::PickerFieldComponent < Forms::PickerFieldComponent
  I18N_SCOPE = "onboarding.profile_setups.picker_field_component"

  def initialize(form:, field:, **options)
    super(
      form: form,
      field: field,
      rows: self.class.rows_for(field),
      label: I18n.t("#{I18N_SCOPE}.#{field}_label", default: field.to_s.humanize),
      help_text: I18n.t("#{I18N_SCOPE}.#{field}_help", default: nil),
      placeholder: I18n.t("#{I18N_SCOPE}.placeholder"),
      **options
    )
  end

  # Priority choices lead, the rest follow alphabetically; one flat list, no headers.
  def self.rows_for(field)
    priority = Array(Onboarding::OptionsService.priority_options_for(field))
    rest = Onboarding::OptionsService.options_for(field).reject { |o| priority.any? { |p| p.last == o.last } }
    (priority + rest).map { |label, value| { value: value.to_s, label: label } }
  end
end
