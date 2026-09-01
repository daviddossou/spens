# frozen_string_literal: true

class AccountSuggestionsService
  def initialize(space)
    @space = space
  end

  def all
    user_accounts = ranked_accounts.pluck(:name)
    templates = Account.templates(I18n.locale).values

    (user_accounts + templates.reject { |name| taken?(name, user_accounts) }).uniq
  end

  # Template names the space has not used yet — what a NEW account could be
  # called, with nothing that already exists mixed in.
  def template_names
    existing = @space.accounts.pluck(:name)
    Account.templates(I18n.locale).values.reject { |name| taken?(name, existing) }
  end

  def all_with_balances
    user_accounts = ranked_accounts.pluck(:name, :balance)
    user_suggestions = user_accounts.map { |name, balance| { name: name, balance: balance } }

    templates = Account.templates(I18n.locale).values
    template_suggestions = templates.map { |name| { name: name, balance: nil } }

    existing_names = user_accounts.map(&:first)
    template_suggestions.reject! { |t| taken?(t[:name], existing_names) }

    user_suggestions + template_suggestions
  end

  def defaults
    user_accounts = ranked_accounts.pluck(:name)

    return user_accounts if user_accounts.length >= 10

    template_suggestions = Account.templates(I18n.locale).values
    available_templates = template_suggestions.reject { |name| taken?(name, user_accounts) }
    needed = 10 - user_accounts.length

    user_accounts + available_templates.take(needed)
  end

  def defaults_with_balances
    user_accounts = ranked_accounts.pluck(:name, :balance)
    user_suggestions = user_accounts.map { |name, balance| { name: name, balance: balance } }

    return user_suggestions if user_suggestions.length >= 10

    templates = Account.templates(I18n.locale).values
    template_suggestions = templates.map { |name| { name: name, balance: nil } }

    existing_names = user_accounts.map(&:first)
    available_templates = template_suggestions.reject { |t| taken?(t[:name], existing_names) }

    needed = 10 - user_suggestions.length
    user_suggestions + available_templates.take(needed)
  end

  private

  # A template duplicates an account when the NAMES match once the leading emoji,
  # the case and the accents are set aside: an account called "Banque" and the
  # "🏦 Banque" template are the same account, and listing both offers a choice
  # between two identical rows.
  def taken?(template_name, existing_names)
    existing_names.any? { |name| fold(name) == fold(template_name) }
  end

  def fold(name)
    name.to_s.sub(/\A[^[:alnum:]]+/, "").strip.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase
  end

  # Most recently touched accounts first, with the most-used (by number of
  # transactions) winning ties — so the account a user just reached for sits at the top
  # of every picker. left_joins keeps accounts that have no transactions yet.
  def ranked_accounts
    @space.accounts
          .active
          .left_joins(:transactions)
          .group("accounts.id")
          .order(updated_at: :desc)
          .order(Arel.sql("COUNT(transactions.id) DESC"))
  end
end
