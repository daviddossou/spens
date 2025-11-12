# frozen_string_literal: true

class AccountSuggestionsService
  def initialize(user)
    @user = user
  end

  def all
    user_accounts = @user.accounts.order(updated_at: :desc).pluck(:name)
    templates = Account.templates(I18n.locale).values

    (user_accounts + templates).uniq
  end

  def defaults
    user_accounts = @user.accounts.order(updated_at: :desc).pluck(:name)

    return user_accounts if user_accounts.length >= 10

    template_suggestions = Account.templates(I18n.locale).values
    available_templates = template_suggestions - user_accounts
    needed = 10 - user_accounts.length

    user_accounts + available_templates.take(needed)
  end
end
