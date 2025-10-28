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
    # Get all account template suggestions from i18n
    I18n.t("account_templates").values
  end
end
