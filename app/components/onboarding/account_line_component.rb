# frozen_string_literal: true

class Onboarding::AccountLineComponent < ViewComponent::Base
  attr_reader :form, :index, :transaction, :currency, :can_remove

  def initialize(form:, index:, transaction:, currency:, can_remove: false)
    @form = form
    @index = index
    @transaction = transaction
    @currency = currency
    @can_remove = can_remove
  end

  def account_suggestions
    I18n.t("account_templates").values
  end

  # Picker rows: the emoji leading a template name becomes the row icon; the full
  # name stays the submitted value.
  def account_rows
    account_suggestions.map do |name|
      icon, label = helpers.picker_icon_and_label(name)
      { value: name, label: label, icon: icon }
    end
  end
end
