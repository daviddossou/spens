# frozen_string_literal: true

class TransactionTypeSuggestionsService
  def initialize(user, kind)
    @user = user
    @kind = kind
  end

  def all
    user_types = @user.transaction_types.where(kind: @kind).order(updated_at: :desc).pluck(:name)
    templates = TransactionType.templates(I18n.locale)
    template_suggestions = templates.select { |_k, attrs| attrs[:kind] == @kind }.map { |_k, attrs| attrs[:name] }

    (user_types + template_suggestions).uniq
  end

  def defaults
    user_types = @user.transaction_types.where(kind: @kind).order(updated_at: :desc).pluck(:name)

    return user_types if user_types.length >= 15

    default_keys = TransactionType.default_template_keys(@kind)
    templates = TransactionType.templates(I18n.locale)

    template_suggestions = default_keys.filter_map do |key|
      templates.dig(key.to_sym, :name) if templates.key?(key.to_sym)
    end

    available_templates = template_suggestions - user_types
    needed = 15 - user_types.length

    user_types + available_templates.take(needed)
  end
end
